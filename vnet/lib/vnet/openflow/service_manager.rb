# -*- coding: utf-8 -*-

module Vnet::Openflow

  class ServiceManager < Manager

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "service_manager: #{message} (dpid:#{@dpid_s}#{values ? ' ' : ''}#{values})"
    end

    def service_initialize(mode, params)
      case mode
      when :arp_lookup then Vnet::Openflow::Services::ArpLookup.new(params)
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
      mac_address = interface[:mac_addresses].first
      ipv4_address = mac_address[1][:ipv4_addresses].first

      # Refactor...
      translated_map = {
        :vif_uuid => interface[:uuid],
        :active_datapath_id => interface[:active_datapath_ids] && interface[:active_datapath_ids].first,
        :service_mac => mac_address[0],
        :service_ipv4 => ipv4_address[:ipv4_address],
        :network_id => ipv4_address[:network_id],
        :network_uuid => 'fff', #network[:uuid],
        :network_type => ipv4_address[:network_type],

        # Refactored:
        :datapath => @datapath,
        :interface => interface,
      }

      item = @items[item_map.id]
      return item if item

      debug log_format('insert', "service:#{item_map.uuid}/#{item_map.id}")

      item = service_initialize(item_map.display_name.to_sym, translated_map)
      return nil if item.nil?

      @items[item_map.id] = item

      # if service_map.vif.mode == 'simulated'

      if translated_map[:active_datapath_id] &&
          translated_map[:active_datapath_id] != @datapath.datapath_id
        return
      end

      cookie = item_map.id | (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT)

      @datapath.packet_manager.insert(item, nil, cookie)

      item
    end    

  end

end
