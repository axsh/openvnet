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
      info "route_manager: route.uuid:#{route_map.uuid.inspect}"
      info "route_manager: route.route_type:#{route_map.route_type.inspect}"
      info "route_manager: route.vif:#{route_map.vif.inspect}"
      info "route_manager: route.route_link:#{route_map.route_link.inspect}"

      route_link = prepare_link(route_map.route_link)

      return if route_link.nil?
      return if route_link[:routes].has_key? route_map.id

      route = {
        :id => route_map.id,
        :uuid => route_map.uuid,
        :vif => prepare_vif(route_map.vif),
        :ipv4_address => route_map.ipv4_address,
        :ipv4_prefix => route_map.ipv4_prefix,
        :ipv4_mask => IPV4_BROADCAST << (32 - route_map.ipv4_prefix),
      }

      if route[:vif].nil?
        warn "route_manager: couldn't prepare router vif (#{route_map.uuid})"
        return
      end

      route_link[:routes][route[:id]] = route

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

    def prepare_link(link_map)
      link = @route_links[link_map.id]
      return link if link

      packet_handler = Routers::RouteLink.new(datapath: @datapath,
                                              route_link_id: link_map.id)

      link = {
        :id => link_map.id,
        :mac_addr => Trema::Mac.new(link_map.mac_address),
        :routes => {},
        :packet_handler => packet_handler
      }

      cookie = link[:id] | (COOKIE_PREFIX_ROUTE_LINK << COOKIE_PREFIX_SHIFT)

      @route_links[link_map.id] = link
      @datapath.packet_manager.insert(packet_handler, nil, cookie)

      route_link_md = md_create(:route_link => link[:id])

      flows = []
      flows << Flow.create(TABLE_HOST_PORTS, 30, {
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
        :service_cookie => service_map.id | (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT),
        :mac_addr => Trema::Mac.new(vif_map.mac_addr),
        :ipv4_address => IPAddr.new(vif_map.ipv4_address, Socket::AF_INET),
      }

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

      create_vif_flows(vif)
      vif
    end

    def create_route_flows(route_link, route)
      cookie = route[:id] | (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)

      network_md    = md_create(route[:vif][:network_type] => route[:vif][:network_id])
      route_link_md = md_create(:route_link => route_link[:id])

      flows = []
      flows << Flow.create(TABLE_ROUTER_SRC, 40,
                           network_md.merge({ :eth_dst => route[:vif][:mac_addr],
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
                             :eth_src => route[:vif][:mac_addr]
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
    end

    def create_vif_flows(vif)
      cookie = vif[:id] | (COOKIE_PREFIX_VIF << COOKIE_PREFIX_SHIFT)
      network_md = md_create(:network => vif[:network_id])

      if vif[:network_type] == :physical_network
        goto_table = TABLE_PHYSICAL_DST
      else
        goto_table = TABLE_VIRTUAL_DST
      end

      flows = []
      flows << Flow.create(TABLE_ROUTER_ENTRY, 40,
                           network_md.merge({ :eth_dst => vif[:mac_addr],
                                              :eth_type => 0x0800,
                                              :ipv4_dst => vif[:ipv4_address]
                                            }),
                           nil, {
                             :cookie => cookie,
                             :goto_table => goto_table
                           })
      flows << Flow.create(TABLE_ROUTER_ENTRY, 30,
                           network_md.merge({ :eth_dst => vif[:mac_addr],
                                              :eth_type => 0x0800
                                            }),
                           nil, {
                             :cookie => cookie,
                             :goto_table => goto_table
                           })
      
      @datapath.add_flows(flows)
    end
  end

end
