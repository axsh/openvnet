# -*- coding: utf-8 -*-

module Vnet::Openflow

  class ServiceManager < Manager

    #
    # Events:
    #
    subscribe_event :added_service # TODO Check if needed.
    subscribe_event :removed_service # TODO Check if needed.

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} service_manager: #{message}" + (values ? " (#{values})" : '')
    end

    def service_initialize(mode, params)
      case mode
      when :dhcp       then Vnet::Openflow::Services::Dhcp.new(params)
      when :router     then Vnet::Openflow::Services::Router.new(params)
      else
        error log_format('failed to create service',  "name:#{mode}")
        nil
      end
    end

    def select_item(filter)
      MW::NetworkService[filter]
    end

    def create_item(item_map, params)
      # TODO: Refactor this to be thread safe same as interface
      # manager.
      interface = @datapath.interface_manager.item(:id => item_map.interface_id)
      return nil if interface.nil?
      
      item = @items[item_map.id]
      return item if item

      debug log_format("insert #{item_map.uuid}/#{item_map.id}", "mode:#{item_map.display_name.to_sym}")

      mac_address = interface.mac_addresses.first
      ipv4_address = mac_address[1][:ipv4_addresses].first

      item = service_initialize(item_map.display_name.to_sym,
                                datapath: @datapath,
                                manager: self,
                                id: item_map.id,
                                uuid: item_map.uuid,
                                interface_id: interface.id)
      return nil if item.nil?

      @items[item_map.id] = item

      # if service_map.vif.mode == 'simulated'

      # if interface.active_datapath_id &&
      #     interface.active_datapath_id != @datapath.datapath_id
      #   return
      # end

      item.install
      item
    end    

    #
    # Event handlers:
    #

  end

end
