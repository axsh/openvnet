# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class RouteManager
    include Constants
    include Celluloid
    include Celluloid::Logger
    
    def initialize(dp)
      @datapath = dp
      @routes = {}
      @route_links = {}

      @cookie = @datapath.switch.cookie_manager.acquire(:route)
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
      info "route_manager: route.route_link:#{route_map.vif.inspect}"

      info "route_manager: dp_map:#{dp_map.inspect}"

      return if @routes.has_key? route_map.uuid

      

    end

  end

end
