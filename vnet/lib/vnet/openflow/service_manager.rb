# -*- coding: utf-8 -*-

module Vnet::Openflow

  class ServiceManager < Manager

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

    def create_item(item_map)
      return nil if item_map.nil?

      interface = @datapath.interface_manager.item(:id => item_map.vif_id)
      
      # Refactor... (Create Interface class with base OpenStruct)
      mac_address = interface.mac_addresses.first
      ipv4_address = mac_address[1][:ipv4_addresses].first

      translated_map = {
        :datapath => @datapath,
        :interface_id => interface.id,
      }

      item = @items[item_map.id]
      return item if item

      debug log_format('insert', "service:#{item_map.uuid}/#{item_map.id}")

      item = service_initialize(item_map.display_name.to_sym, translated_map)
      return nil if item.nil?

      @items[item_map.id] = item

      # if service_map.vif.mode == 'simulated'

      # if interface.active_datapath_id &&
      #     interface.active_datapath_id != @datapath.datapath_id
      #   return
      # end

      cookie = item_map.id | (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT)

      @datapath.packet_manager.insert(item, nil, cookie)

      item
    end    

  end

end
