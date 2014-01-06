# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager < Manager

    def initialize(dp_info)
      super

      @route_links = {}
      @interfaces = {}
    end

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

      route_link = @dp_info.router_manager.update(event: :activate_route,
                                                  id: route_map.route_link_id,
                                                  route_id: route_map.id)
      @route_links[route_link.id] = true if route_link

      interface = prepare_interface(route_map.interface_id)

      if interface.nil?
        warn log_format('couldn\'t prepare router interface', "#{route_map.uuid}")
        return
      end

      route.install
    end

    def prepare_network(network_map, dp_map)
      network_map.batch.routes.commit.each { |route_map|
        if !@route_links.has_key?(route_map.route_link_id)
          route_map.batch.on_other_networks(network_map.id).commit.each { |other_route_map|
            # Replace with a lightweight methods.
            self.insert(other_route_map)
          }
        end

        self.insert(route_map)
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

    def prepare_interface(interface_id)
      interface_item = @dp_info.interface_manager.item(id: interface_id)
      return nil if interface_item.nil?

      info log_format('from interface_manager' , "#{interface_item.uuid}/#{interface_id} mode:#{interface_item.mode}")

      interface = interface_item && @interfaces[interface_item.id]
      return interface if interface

      if interface_item.mode != :simulated && interface_item.mode != :remote
        info log_format('only interfaces with mode \'simulated\' or \'remote\' are supported',
                        "uuid:#{interface_item.uuid} mode:#{interface_item.mode}")
        return
      end

      interface = {
        :id => interface_item.id,
        :use_datapath_id => nil,

        :mode => interface_item.mode,
      }

      @interfaces[interface_item.id] = interface

      if interface_item.mode == :remote
        interface[:use_datapath_id] = interface_item.owner_datapath_ids && interface_item.owner_datapath_ids.first

        # if interface[:use_datapath_id]
          # @dp_info.interface_manager.async.update_item(event: :enable_router_ingress,
          #                                              id: interface[:id])
          @dp_info.interface_manager.async.update_item(event: :enable_router_egress,
                                                       id: interface[:id])
        # end

        return interface
      end

      datapath_id = @datapath_info.datapath_map.id

      if interface_item.active_datapath_ids &&
          !interface_item.active_datapath_ids.include?(datapath_id)
        interface[:use_datapath_id] = interface_item.active_datapath_ids.first
      end

      if interface[:use_datapath_id].nil?
        @dp_info.interface_manager.async.update_item(event: :enable_router_ingress,
                                                     id: interface[:id])
        @dp_info.interface_manager.async.update_item(event: :enable_router_egress,
                                                     id: interface[:id])
      end

      interface
    end

  end

end
