# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers
    
    ROUTE_COMMIT = {:fill => [:route_link, :iface => [:network_services, :network]]}

    def initialize(dp)
      @datapath = dp
      @route_links = {}
      @ifaces = {}
    end

    def insert(route_map)
      route_link = prepare_link(route_map.route_link)

      return if route_link.nil?
      return if route_link[:routes].has_key? route_map.id

      info "route_manager.insert: id:#{route_map.id} uuid:#{route_map.uuid}"
      info "route_manager.insert: route.route_type:#{route_map.route_type}"
      info "route_manager.insert: route.iface: id:#{route_map.iface.id} uuid:#{route_map.iface.uuid}"
      info "route_manager.insert: route.route_link: id:#{route_map.route_link.id} uuid:#{route_map.route_link.uuid}"

      route = {
        :id => route_map.id,
        :uuid => route_map.uuid,
        :iface => nil,
        :ipv4_address => route_map.ipv4_address,
        :ipv4_prefix => route_map.ipv4_prefix,
        :ipv4_mask => IPV4_BROADCAST << (32 - route_map.ipv4_prefix),
      }

      route_link[:routes][route[:id]] = route

      route[:iface] = prepare_iface(route_map.iface)

      if route[:iface].nil?
        warn "route_manager: couldn't prepare router iface (#{route_map.uuid})"
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
                                                 :goto_table => TABLE_ROUTER_LINK
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
                                                   :goto_table => TABLE_ROUTER_LINK
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

    def prepare_iface(iface_map)
      iface = @ifaces[iface_map.id]
      return iface if iface

      service_map = iface_map.network_services.detect { |service| service.display_name == 'router' }

      if service_map.nil?
        warn "route_manager: could not find 'router' service for iface (#{iface_map.uuid})"
        return nil
      end

      iface = {
        :id => iface_map.id,
        :network_id => iface_map.network_id,
        :use_datapath_id => nil,
        :service_cookie => service_map.id | (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT),
        :mac_addr => Trema::Mac.new(iface_map.mac_addr),
        :ipv4_address => IPAddr.new(iface_map.ipv4_address, Socket::AF_INET),
      }

      datapath_id = @datapath.datapath_map.id

      if iface_map.owner_datapath_id
        if iface_map.owner_datapath_id == datapath_id
          iface_map.batch.update(:active_datapath_id => datapath_id).commit
        else
          iface[:use_datapath_id] = iface_map.owner_datapath_id
        end
      end

      case iface_map.network && iface_map.network.network_mode
      when 'physical'
        iface[:require_iface] = false
        iface[:network_type] = :physical_network
      when 'virtual'
        iface[:require_iface] = true
        iface[:network_type] = :virtual_network
      else
        warn "route_manager: iface does not have a known network mode (#{iface_map.uuid})"
        return nil
      end

      @ifaces[iface_map.id] = iface

      create_iface_flows(iface) if iface[:use_datapath_id].nil?

      iface
    end

    def create_route_flows(route_link, route)
      cookie = route[:id] | (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)

      route_link_md = md_create(:route_link => route_link[:id])

      flows = []

      if route[:iface][:use_datapath_id].nil?
        network_md = md_create(route[:iface][:network_type] => route[:iface][:network_id])

        flows << Flow.create(TABLE_ROUTER_SRC, 40,
                             network_md.merge({ :eth_dst => route[:iface][:mac_addr],
                                                :eth_type => 0x0800,
                                                :ipv4_src => route[:ipv4_address],
                                                :ipv4_src_mask => route[:ipv4_mask],
                                              }),
                             nil,
                             route_link_md.merge({ :cookie => cookie,
                                                   :goto_table => TABLE_ROUTER_LINK
                                                 }))
        flows << Flow.create(TABLE_ROUTER_LINK, 40,
                             route_link_md.merge({ :eth_type => 0x0800,
                                                   :ipv4_dst => route[:ipv4_address],
                                                   :ipv4_dst_mask => route[:ipv4_mask],
                                                 }), {
                               :eth_src => route[:iface][:mac_addr]
                             },
                             network_md.merge({ :cookie => cookie,
                                                :goto_table => TABLE_ROUTER_DST
                                              }))

        @datapath.add_flows(flows)

        link_cookie = route_link[:id] | (COOKIE_PREFIX_ROUTE_LINK << COOKIE_PREFIX_SHIFT)

        pm = @datapath.packet_manager
        pm.dispatch(link_cookie) { |key, handler|
          route_cookie = handler.insert_route(route)
          pm.link_cookies(key, route_cookie) if route_cookie
        }

      else
        datapath_md = md_create(:datapath => route[:iface][:use_datapath_id])

        flows << Flow.create(TABLE_ROUTER_LINK, 40,
                             route_link_md.merge({ :eth_type => 0x0800,
                                                   :ipv4_dst => route[:ipv4_address],
                                                   :ipv4_dst_mask => route[:ipv4_mask],
                                                 }), {
                               :eth_dst => route_link[:mac_addr]
                             },
                             datapath_md.merge({ :cookie => cookie,
                                                 :goto_table => TABLE_OUTPUT_DP_ROUTE_LINK
                                               }))

        @datapath.add_flows(flows)
      end
    end

    def create_iface_flows(iface)
      cookie = iface[:id] | (COOKIE_PREFIX_VIF << COOKIE_PREFIX_SHIFT)
      network_md = md_create(:network => iface[:network_id])

      if iface[:network_type] == :physical_network
        goto_table = TABLE_PHYSICAL_DST
      else
        goto_table = TABLE_VIRTUAL_DST
      end

      flows = []
      flows << Flow.create(TABLE_ROUTER_ENTRY, 40,
                           network_md.merge({ :eth_dst => iface[:mac_addr],
                                              :eth_type => 0x0800,
                                              :ipv4_dst => iface[:ipv4_address]
                                            }),
                           nil, {
                             :cookie => cookie,
                             :goto_table => goto_table
                           })
      flows << Flow.create(TABLE_ROUTER_ENTRY, 30,
                           network_md.merge({ :eth_dst => iface[:mac_addr],
                                              :eth_type => 0x0800
                                            }),
                           nil, {
                             :cookie => cookie,
                             :goto_table => TABLE_ROUTER_SRC
                           })

      @datapath.add_flows(flows)
    end

  end

end
