# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager < Manager

    #
    # Events:
    #

    #
    # Refactor:
    #

    def insert(route_map)
      return if @items[route_map.id]

      info log_format("insert #{route_map.uuid}/#{route_map.id}", "interface_id:#{route_map.interface_id}")

      route = Routes::Base.new(dp_info: @dp_info,
                               manager: self,
                               map: route_map)

      @items[route.id] = route

      route.install
    end

    def prepare_network(network_map, dp_map)
      routes = network_map.batch.routes.commit
      return if routes.nil?

      routes.map { |route_map|
        route_map.route_link_id
      }.uniq { |route_link_id|
        @dp_info.router_manager.async.retrieve(id: route_link_id)
      }
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} route_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

  end

end
