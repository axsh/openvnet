# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers
    
    def initialize(dp)
      @datapath = dp
      @routes = {}
      @route_links = {}
      @vifs = {}
    end

    def insert(network_map, dp_map, route_map)
      info "route_manager: route.uuid:#{route_map.uuid.inspect}"
      info "route_manager: route.route_type:#{route_map.route_type.inspect}"
      info "route_manager: route.vif:#{route_map.vif.inspect}"
      info "route_manager: route.route_link:#{route_map.route_link.inspect}"
      # info "route_manager: dp_map:#{dp_map.inspect}"

      return if @routes.has_key? route_map.uuid

      route = {
        :id => route_map.id,
        :uuid => route_map.uuid,
        :vif => prepare_vif(route_map.vif),
        :route_link => prepare_link(route_map.route_link),
        :ipv4_address => route_map.ipv4_address,
        :ipv4_prefix => route_map.ipv4_prefix,
        :ipv4_mask => IPV4_BROADCAST << (32 - route_map.ipv4_prefix),
      }

      if route[:vif].nil? || route[:route_link].nil?
        warn "route_manager: couldn't prepare vif or route link"
        return
      end

      @routes[route_map.uuid] = route

      cookie = route[:id] | (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)

      route_link_md = md_create(:route_link => route[:route_link][:id])
      # Rewrite to use route link?..
      network_md    = md_create(:virtual_network => route[:vif][:network_id])

      flows = []
      flows << Flow.create(TABLE_ROUTER_SRC, 40,
                           network_md.merge({ :eth_dst => route[:vif][:mac_addr],
                                              :eth_type => 0x0800,
                                              :ipv4_src => route[:ipv4_address],
                                              :ipv4_src_mask => route[:ipv4_mask],
                                            }), {
                           }, route_link_md.merge({ :cookie => cookie,
                                                    :goto_table => TABLE_ROUTER_LINK
                                                  }))
      flows << Flow.create(TABLE_ROUTER_LINK, 40,
                           route_link_md.merge({ :eth_type => 0x0800,
                                                 :ipv4_dst => route[:ipv4_address],
                                                 :ipv4_dst_mask => route[:ipv4_mask],
                                               }), {
                             :eth_src => route[:vif][:mac_addr]
                           }, network_md.merge({ :cookie => cookie,
                                                 :goto_table => TABLE_ROUTER_DST
                                               }))

      @datapath.add_flows(flows)

      pm = @datapath.packet_manager

      pm.dispatch(route[:vif][:service_cookie]) { |key, handler|
        route_cookie = handler.insert_route(route)
        pm.link_cookies(key, route_cookie) if route_cookie
      }
    end

    def prepare_network(network_map, dp_map)
      network_map.batch.routes.commit(:fill => [:route_link, :vif => :network_services]).each { |route|
        self.insert(network_map, dp_map, route)
      }
    end

    private

    def prepare_link(link_map)
      link = @route_links[link_map.id]
      return link if link

      link = {
        :id => link_map.id,
        :mac_addr => Trema::Mac.new(link_map.mac_address),
      }

      @route_links[link_map.id] = link

      cookie = link[:id] | (COOKIE_PREFIX_ROUTE_LINK << COOKIE_PREFIX_SHIFT)

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

      @vifs[vif_map.id] = vif

      cookie = vif[:id] | (COOKIE_PREFIX_VIF << COOKIE_PREFIX_SHIFT)
      network_md = md_create(:virtual_network => vif[:network_id])

      flows = []
      flows << Flow.create(TABLE_ROUTER_ENTRY, 40,
                           network_md.merge({ :eth_dst => vif[:mac_addr],
                                              :eth_type => 0x0800,
                                              :ipv4_dst => vif[:ipv4_address]
                                            }),
                           nil, {
                             :cookie => cookie,
                             :goto_table => TABLE_VIRTUAL_DST
                           })
      flows << Flow.create(TABLE_ROUTER_ENTRY, 30,
                           network_md.merge({ :eth_dst => vif[:mac_addr],
                                              :eth_type => 0x0800
                                            }),
                           nil, {
                             :cookie => cookie,
                             :goto_table => TABLE_ROUTER_SRC
                           })
      
      @datapath.add_flows(flows)
      vif
    end

  end

end
