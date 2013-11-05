# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager < Manager

    ROUTE_COMMIT = {:fill => [:route_link]}

    def initialize(dp_info)
      super

      @route_links = {}
      @interfaces = {}
    end

    #
    # Refactor:
    #

    def insert(route_map)
      route_link = prepare_link(route_map.route_link)

      return if route_link.nil?
      return if route_link.routes.has_key? route_map.id

      info log_format("insert #{route_map.uuid}/#{route_map.id}", "interface_id:#{route_map.interface_id}")

      route = Routes::Base.new(dp_info: @dp_info,
                               manager: self,
                               map: route_map)

      @items[route.id] = route

      route_link.routes[route.id] = route

      interface = prepare_interface(route_map.interface_id)

      if interface.nil?
        warn log_format('couldn\'t prepare router interface', "#{route_map.uuid}")
        return
      end

      route.network_id = interface[:network_id]
      route.use_datapath_id = interface[:use_datapath_id]
      route.install
    end

    def prepare_network(network_map, dp_map)
      network_map.batch.routes.commit(ROUTE_COMMIT).each { |route_map|
        if !@route_links.has_key?(route_map.route_link.id)
          route_map.batch.on_other_networks(network_map.id).commit(ROUTE_COMMIT).each { |other_route_map|
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


    #
    # Refactor:
    #

    def datapath_route_link(rl_map)
      @datapath_info.datapath_map.batch.datapath_route_links_dataset.where(:route_link_id => rl_map.id).all.commit
    end

    def dp_rl_on_segment(rl_map)
      rl_map.batch.datapath_route_links_dataset.on_segment(@datapath_info.datapath_map).all.commit
    end

    def prepare_link(rl_map)
      link = @route_links[rl_map.id]
      return link if link

      route_link = Routers::RouteLink.new(dp_info: @dp_info, map: rl_map)
      @route_links[route_link.id] = route_link

      datapath_route_link(rl_map).each { |dp_rl_map|
        route_link.set_dp_route_link(dp_rl_map)
      }

      dp_rl_on_segment(rl_map).each { |dp_rl_map|
        route_link.add_datapath_on_segment(dp_rl_map)
      }

      route_link.install
      route_link
    end

    def prepare_interface(interface_id)
      interface_item = @dp_info.interface_manager.item(id: interface_id)
      return nil if interface_item.nil?

      info log_format('from interface_manager' , "#{interface_item.uuid}/#{interface_id}")

      interface = interface_item && @interfaces[interface_item.id]
      return interface if interface

      if interface_item.mode != :simulated && interface_item.mode != :remote
        info log_format('only interfaces with mode \'simulated\' or \'remote\' are supported',
                        "uuid:#{interface_item.uuid} mode:#{interface_item.mode}")
        return
      end

      mac_info = interface_item.mac_addresses.first

      if mac_info.nil? ||
          mac_info[1][:ipv4_addresses].first.nil?
        warn log_format('could not find ipv4 address')
        return nil
      end

      ipv4_info = mac_info[1][:ipv4_addresses].first

      interface = {
        :id => interface_item.id,
        :use_datapath_id => nil,

        :mode => interface_item.mode,
        :network_id => ipv4_info[:network_id],
      }

      @interfaces[interface_item.id] = interface

      if interface_item.mode == :remote
        interface[:use_datapath_id] = interface_item.owner_datapath_ids && interface_item.owner_datapath_ids.first

        return interface
      end

      datapath_id = @datapath_info.datapath_map.id

      # Fix this...
      if interface_item.owner_datapath_ids
        if interface_item.owner_datapath_ids.include? datapath_id
          @dp_info.interface_manager.update_item(event: :active_datapath_id,
                                                 id: interface_item.id,
                                                 datapath_id: datapath_id)
        else
          interface[:use_datapath_id] = interface_item.owner_datapath_ids.first
        end
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
