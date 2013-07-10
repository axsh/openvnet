# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class RouteManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers
    
    def initialize(dp)
      @datapath = dp
      @routes = {}
      @route_links = {}
    end

    def prepare_network(network_map, dp_map)
      network_map.batch.routes.commit(:fill => [:route_link, :vif]).each { |route|
        self.insert(network_map, dp_map, route)
      }
    end

    def insert(network_map, dp_map, route_map)
      info "route_manager: route.uuid:#{route_map.uuid.inspect}"
      info "route_manager: route.route_type:#{route_map.route_type.inspect}"
      info "route_manager: route.vif:#{route_map.vif.inspect}"
      info "route_manager: route.route_link:#{route_map.route_link.inspect}"

      info "route_manager: dp_map:#{dp_map.inspect}"

      return if @routes.has_key? route_map.uuid

      route = {
        :cookie => @datapath.switch.cookie_manager.acquire(:route),
        :network_id => route_map.vif.network_id,
        :mac_addr => Trema::Mac.new(route_map.vif.mac_addr),
      }

      if route[:cookie].nil?
        error "route_manager: couldn't acquire flow cookie"
        return
      end

      @routes[route_map.uuid] = route

      flows = []
      flows << Flow.create(TABLE_ROUTER_ENTRY, 40,
                           md_create(:network => route[:network_id]).merge!(:eth_dst => route[:mac_addr]), {
                           }, {
                             :cookie => route[:cookie],
                             :goto_table => TABLE_ROUTER_SRC
                           })

      @datapath.add_flows(flows)
    end

  end

end
