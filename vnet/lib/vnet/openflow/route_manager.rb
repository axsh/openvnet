# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers

    ROUTE_COMMIT = {:fill => [:route_link, :vif => [:network_services, :network]]}

    def initialize(dp)
      @datapath = dp
      @route_links = {}
      @vifs = {}
    end

    def insert(route_map)
      route_link = prepare_link(route_map.route_link)

      return if route_link.nil?
      return if route_link[:routes].has_key? route_map.id

      info "route_manager.insert: id:#{route_map.id} uuid:#{route_map.uuid}"
      info "route_manager.insert: route.route_type:#{route_map.route_type}"
      info "route_manager.insert: route.vif: id:#{route_map.vif.id} uuid:#{route_map.vif.uuid}"
      info "route_manager.insert: route.route_link: id:#{route_map.route_link.id} uuid:#{route_map.route_link.uuid}"

      route = {
        :id => route_map.id,
        :uuid => route_map.uuid,
        :vif => nil,
        :ipv4_address => route_map.ipv4_address,
        :ipv4_prefix => route_map.ipv4_prefix,
        :ingress => route_map.ingress,
        :egress => route_map.egress,
      }

      route_link[:routes][route[:id]] = route

      route[:vif] = prepare_vif(route_map.vif)

      if route[:vif].nil?
        warn "route_manager: couldn't prepare router vif (#{route_map.uuid})"
        return
      end

      create_route_flows(route_link, route)
    end

    def prepare_network(network_map, dp_map)
      network_map.batch.routes.commit(ROUTE_COMMIT).each { |route_map|
        if !@route_links.has_key?(route_map.route_link.id)
          route_map.batch.on_other_networks.commit(ROUTE_COMMIT).each { |other_route_map|
            # Replace with a lightweight methods.
            self.insert(other_route_map)
          }
        end

        self.insert(route_map)
      }
    end

    private

    def datapath_route_link(rl_map)
      @datapath.datapath_batch.datapath_route_links_dataset.where(:route_link_id => rl_map.id).all.commit
    end

    def dp_rl_on_segment(rl_map)
      rl_map.batch.datapath_route_links_dataset.on_segment(@datapath.datapath_map).all.commit
    end

    def prepare_link(rl_map)
      link = @route_links[rl_map.id]
      return link if link

      mac_address = Trema::Mac.new(rl_map.mac_address)
      packet_handler = Routers::RouteLink.new(datapath: @datapath,
                                              route_link_id: rl_map.id,
                                              mac_address: mac_address)

      link = {
        :id => rl_map.id,
        :mac_addr => mac_address,
        :routes => {},
        :packet_handler => packet_handler
      }

      cookie = link[:id] | (COOKIE_PREFIX_ROUTE_LINK << COOKIE_PREFIX_SHIFT)

      @route_links[rl_map.id] = link
      @datapath.packet_manager.insert(packet_handler, nil, cookie)

      tunnel_md = md_create(:tunnel => nil)
      route_link_md = md_create(:route_link => link[:id])

      # TODO: Move flow creation to Routers::RouteLink...

      flows = []
      flows << Flow.create(TABLE_TUNNEL_NETWORK_IDS, 30, {
                             :tunnel_id => TUNNEL_ROUTE_LINK,
                             :eth_dst => link[:mac_addr]
                           }, nil,
                           route_link_md.merge({ :cookie => cookie,
                                                 :goto_table => TABLE_ROUTER_EGRESS
                                               }))
      flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                             :eth_dst => link[:mac_addr]
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                             :eth_src => link[:mac_addr]
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_OUTPUT_DP_ROUTE_LINK, 4, {
                             :eth_dst => mac_address
                           }, {
                             :tunnel_id => TUNNEL_ROUTE_LINK
                           }, tunnel_md.merge({ :goto_table => TABLE_OUTPUT_DATAPATH,
                                                :cookie => cookie
                                              }))

      # Handle MAC2MAC packets for this route link using a unique MAC
      # address for this datapath, route link pair.
      datapath_route_link(rl_map).each { |dp_rl_map|
        flows << Flow.create(TABLE_HOST_PORTS, 30, {
                               :eth_dst => Trema::Mac.new(dp_rl_map.link_mac_addr)
                             }, nil,
                             route_link_md.merge({ :cookie => cookie,
                                                   :goto_table => TABLE_ROUTER_EGRESS
                                                 }))
        flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                               :eth_dst => Trema::Mac.new(dp_rl_map.link_mac_addr)
                             }, nil, {
                               :cookie => cookie
                             })
      }

      # Use the datapath id in the metadata field and the route link
      # MAC address in the destination field to figure out the MAC2MAC
      # datapath, route link pair MAC address to use.
      #
      # If not found it is assumed to be using a tunnel where the
      # route link MAC address is to be used.
      dp_rl_on_segment(rl_map).each { |dp_rl_map|
        datapath_md = md_create(:datapath => dp_rl_map.datapath_id)
        mac2mac_md = md_create(:mac2mac => nil)

        flows << Flow.create(TABLE_OUTPUT_DP_ROUTE_LINK, 5,
                             datapath_md.merge(:eth_dst => mac_address), {
                               :eth_dst => Trema::Mac.new(dp_rl_map.link_mac_addr)
                             }, mac2mac_md.merge({ :goto_table => TABLE_OUTPUT_DATAPATH,
                                                   :cookie => cookie
                                                 }))
      }

      # ROUTER_DST catch unknown subnets. ??? (or load all subnets)

      @datapath.add_flows(flows)
      link
    end

    def prepare_vif(vif_map)
      vif = @vifs[vif_map.id]
      return vif if vif

      service_map = vif_map.network_services.detect { |service| service.display_name == 'router' }

      if service_map.nil?
        warn "route_manager: could not find 'router' service for vif (#{vif_map.uuid})"
        return nil
      end

      vif = {
        :id => vif_map.id,
        :network_id => vif_map.network_id,
        :use_datapath_id => nil,
        :service_cookie => service_map.id | (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT),
        :mac_addr => Trema::Mac.new(vif_map.mac_addr),
        :ipv4_address => IPAddr.new(vif_map.ipv4_address, Socket::AF_INET),
      }

      datapath_id = @datapath.datapath_map.id

      if vif_map.owner_datapath_id
        if vif_map.owner_datapath_id == datapath_id
          vif_map.batch.update(:active_datapath_id => datapath_id).commit
        else
          vif[:use_datapath_id] = vif_map.owner_datapath_id
        end
      end

      case vif_map.network && vif_map.network.network_mode
      when 'physical'
        vif[:require_vif] = false
        vif[:network_type] = :physical_network
      when 'virtual'
        vif[:require_vif] = true
        vif[:network_type] = :virtual_network
      else
        warn "route_manager: vif does not have a known network mode (#{vif_map.uuid})"
        return nil
      end

      @vifs[vif_map.id] = vif

      create_vif_flows(vif) if vif[:use_datapath_id].nil?

      vif
    end

    def create_route_flows(route_link, route)
      cookie = route[:id] | (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)

      flows = []
      route_link_md = md_create(:route_link => route_link[:id])

      if is_ipv4_broadcast(route[:ipv4_address], route[:ipv4_prefix])
        priority = 30
      else
        priority = 31
      end

      subnet_dst = match_ipv4_subnet_dst(route[:ipv4_address], route[:ipv4_prefix])
      subnet_src = match_ipv4_subnet_src(route[:ipv4_address], route[:ipv4_prefix])

      if route[:vif][:use_datapath_id].nil?
        nw_hash = {route[:vif][:network_type] => route[:vif][:network_id]}

        network_md = md_create(nw_hash)
        nw_no_controller_md = md_create(nw_hash.merge(:no_controller => nil))

        rl_reflection_md = md_create({ :route_link => route_link[:id],
                                       :reflection => nil
                                     })

        flows << Flow.create(TABLE_CONTROLLER_PORT, priority,
                             subnet_dst.merge(:eth_src => route[:vif][:mac_addr]),
                             nil,
                             nw_no_controller_md.merge({ :cookie => cookie,
                                                         :goto_table => TABLE_ROUTER_DST
                                                       }))

        if route[:ingress] == true
          flows << Flow.create(TABLE_ROUTER_INGRESS, priority,
                               network_md.merge(subnet_src).merge(:eth_dst => route[:vif][:mac_addr]),
                               nil,
                               rl_reflection_md.merge({ :cookie => cookie,
                                                        :goto_table => TABLE_ROUTER_EGRESS
                                                      }))
        end

        if route[:egress] == true
          flows << Flow.create(TABLE_ROUTER_EGRESS, priority,
                               route_link_md.merge(subnet_dst), {
                                 :eth_src => route[:vif][:mac_addr]
                               },
                               network_md.merge({ :cookie => cookie,
                                                  :goto_table => TABLE_ROUTER_DST
                                                }))

          install_route_handler(route_link, route)
        end

        @datapath.add_flows(flows)

      else
        datapath_md = md_create(:datapath => route[:vif][:use_datapath_id])

        if route[:egress] == true
          flows << Flow.create(TABLE_ROUTER_EGRESS, priority,
                               route_link_md.merge(subnet_dst), {
                                 :eth_dst => route_link[:mac_addr]
                               },
                               datapath_md.merge({ :cookie => cookie,
                                                   :goto_table => TABLE_OUTPUT_DP_ROUTE_LINK
                                                 }))
        end

        @datapath.add_flows(flows)
      end
    end

    def create_vif_flows(vif)
      cookie = vif[:id] | (COOKIE_PREFIX_VIF << COOKIE_PREFIX_SHIFT)
      network_md = md_create(:network => vif[:network_id])

      if vif[:network_type] == :physical_network
        goto_table = TABLE_PHYSICAL_DST
        controller_md = md_create({ :network => vif[:network_id],
                                    :physical => nil,
                                    :no_controller => nil
                                  })
      else
        goto_table = TABLE_VIRTUAL_DST
        controller_md = md_create({ :network => vif[:network_id],
                                    :virtual => nil,
                                    :no_controller => nil
                                  })
      end

      flows = []
      flows << Flow.create(TABLE_ROUTER_CLASSIFIER, 40,
                           network_md.merge({ :eth_dst => vif[:mac_addr],
                                              :eth_type => 0x0800,
                                              :ipv4_dst => vif[:ipv4_address]
                                            }),
                           nil, {
                             :cookie => cookie,
                             :goto_table => goto_table
                           })
      flows << Flow.create(TABLE_CONTROLLER_PORT, 40, {
                             :eth_dst => vif[:mac_addr],
                             :eth_type => 0x0800,
                             :ipv4_dst => vif[:ipv4_address]
                           },
                           nil,
                           controller_md.merge({ :cookie => cookie,
                                                 :goto_table => TABLE_ROUTER_CLASSIFIER
                                               }))
      flows << Flow.create(TABLE_CONTROLLER_PORT, 40, {
                             :eth_dst => vif[:mac_addr],
                             :eth_type => 0x0806
                           },
                           nil,
                           controller_md.merge({ :cookie => cookie,
                                                 :goto_table => TABLE_ROUTER_CLASSIFIER
                                               }))
      flows << Flow.create(TABLE_ROUTER_CLASSIFIER, 30,
                           network_md.merge({ :eth_dst => vif[:mac_addr],
                                              :eth_type => 0x0800
                                            }),
                           nil, {
                             :cookie => cookie,
                             :goto_table => TABLE_ROUTER_INGRESS
                           })

      @datapath.add_flows(flows)
    end

    def install_route_handler(route_link, route)
      link_cookie = route_link[:id] | (COOKIE_PREFIX_ROUTE_LINK << COOKIE_PREFIX_SHIFT)

      pm = @datapath.packet_manager
      pm.dispatch(link_cookie) { |key, handler|
        route_cookie = handler.insert_route(route)
        pm.link_cookies(key, route_cookie) if route_cookie
      }
    end

  end

end
