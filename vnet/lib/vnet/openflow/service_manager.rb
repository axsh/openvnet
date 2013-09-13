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

    def create_item(item_map, params)
      return nil if item_map.nil?

      interface = @datapath.interface_manager.item(:id => item_map.vif_id)
      return nil if interface.nil?
      
      item = @items[item_map.id]
      return item if item

      debug log_format('insert', "service:#{item_map.uuid}/#{item_map.id}")

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

  end

end
