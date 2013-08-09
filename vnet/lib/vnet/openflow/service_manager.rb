# -*- coding: utf-8 -*-

module Vnet::Openflow

  class ServiceManager < Manager

    def initialize(dp)
      super

      @service_cookies = {}
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "service_manager: #{message} (dpid:#{@dpid_s}#{values ? ' ' : ''}#{values})"
    end

    # Refactor...
    def service_initialize(service_name, translated_map)
      case service_name
      when 'arp_lookup' then Vnet::Openflow::Services::ArpLookup.new(translated_map)
      when 'dhcp'       then Vnet::Openflow::Services::Dhcp.new(translated_map)
      when 'router'     then Vnet::Openflow::Services::Router.new(translated_map)
      else
        error log_format('failed to create service',  "#{}")
        nil
      end
    end

    def select_item(filter)
      MW::NetworkService[filter]
    end

    def create_item(item_map)
      return nil if item_map.nil?

      interface = @datapath.interface_manager.interface(:id => item_map.vif_id)
      
      # Refactor...
      mac_address = interface[:mac_addresses].first
      ipv4_address = mac_address[1][:ipv4_addresses].first

      # Refactor...
      translated_map = {
        :datapath => @datapath,
        :vif_uuid => interface[:uuid],
        :active_datapath_id => interface[:active_datapath_ids] && interface[:active_datapath_ids].first,
        :service_mac => mac_address[0],
        :service_ipv4 => ipv4_address[:ipv4_address],
        :network_id => ipv4_address[:network_id],
        :network_uuid => 'fff', #network[:uuid],
        :network_type => ipv4_address[:network_type],
      }

      item = @items[item_map.id]
      return item if item

      debug log_format('insert', "service:#{item_map.uuid}/#{item_map.id}")

      # if service_map.vif.mode == 'simulated'

      item = service_initialize(item_map.display_name, translated_map)
      return nil if item.nil?

      @items[item_map.id] = item

      cookie = item_map.id | (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT)
      @service_cookies[item_map.id] = cookie

      if translated_map[:active_datapath_id] &&
          translated_map[:active_datapath_id] != @datapath.datapath_id
        return
      end

      pm = @datapath.packet_manager

      cookie = pm.insert(item, nil, cookie)

      # Move to interface manager...
      # pm.dispatch(:arp)  { |key, handler| handler.insert_vif(service_map.vif.id, self, service_map.vif) }
      # pm.dispatch(:icmp) { |key, handler| handler.insert_vif(service_map.vif.id, self, service_map.vif) }

      item
    end    

  end

end
