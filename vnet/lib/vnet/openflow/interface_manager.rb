# -*- coding: utf-8 -*-

module Vnet::Openflow

  class InterfaceManager < Manager

    #
    # Events:
    #
    subscribe_event :added_interface # TODO Check if needed.
    subscribe_event :removed_interface # TODO Check if needed.
    subscribe_event LeasedIpv4Address, :leased_ipv4_address
    subscribe_event ReleasedIpv4Address, :released_ipv4_address

    def update_active_datapaths(params)
      interface = internal_detect(params)
      return nil if interface.nil?

      # Refactor this.
      if interface.owner_datapath_ids.nil?
        return if interface.mode != :vif
      end

      # Currently only supports one active datapath id.
      active_datapath_ids = [params[:datapath_id]]

      interface.active_datapath_ids = active_datapath_ids
      MW::Interface.batch[:id => interface.id].update(:active_datapath_id => params[:datapath_id]).commit

      nil
    end

    # Deprecate this...
    def get_ipv4_address(params)
      interface = internal_detect(params)
      return nil if interface.nil?

      interface.get_ipv4_address(params)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} interface_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      return false if params[:mode] && params[:mode] != item.mode
      return false if params[:port_number] && params[:port_number] != item.port_number
      true
    end

    def interface_initialize(mode, params)
      case mode
      when :simulated then Interfaces::Simulated.new(params)
      when :remote then Interfaces::Remote.new(params)
      when :vif then Interfaces::Vif.new(params)
      else
        Interfaces::Base.new(params)
      end
    end

    def select_item(filter)
      # Using fill for ip_leases/ip_addresses isn't going to give us a
      # proper event barrier.
      MW::Interface.batch[filter].commit(:fill => [:ip_leases => :ip_address])
    end

    def create_item(item_map, params)
      mode = is_remote?(item_map) ? :remote : item_map.mode.to_sym

      interface = interface_initialize(mode,
                                       dp_info: @dp_info,
                                       manager: self,
                                       map: item_map)
      return nil if interface.nil?

      @items[item_map.id] = interface

      debug log_format("insert #{item_map.uuid}/#{item_map.id}", "mode:#{mode}")

      # TODO: Make install/uninstall a barrier that enables/disable
      # the creation of flows and ensure that no events gets lost.

      interface.install

      case interface.mode
      when :vif
        port = @dp_info.port_manager.detect(port_name: interface.uuid)
        interface.update_port_number(port[:port_number])
        interface.add_security_groups
      end

      load_addresses(interface, item_map)

      interface # Return nil if interface has been uninstalled.
    end

    def delete_item(item)
      @items.delete(item.id)

      item.uninstall
      item
    end

    # TODO: Convert the loading of addresses to events, and queue them
    # with a 'handle_event' queue to ensure consistency.
    def load_addresses(interface, item_map)
      return if item_map.mac_address.nil?

      mac_address = Trema::Mac.new(item_map.mac_address)
      interface.add_mac_address(mac_address)

      item_map.ip_leases.each { |ip_lease|
        ipv4_address = ip_lease.ip_address.ipv4_address
        next if ipv4_address.nil?

        network_id = ip_lease.network_id
        next if network_id.nil?

        network_info = @dp_info.network_manager.item(id: network_id)
        next if network_info.nil?

        interface.add_ipv4_address(mac_address: mac_address,
                                   network_id: network_id,
                                   network_type: network_info[:type],
                                   ip_lease_id: ip_lease.id,
                                   ipv4_address: IPAddr.new(ipv4_address, Socket::AF_INET))
      }
    end

    def is_remote?(item_map)
      return false if item_map.active_datapath_id.nil? && item_map.owner_datapath_id.nil?

      if item_map.owner_datapath_id
        return item_map.owner_datapath_id != @datapath_id
      end

      return false
    end

    #
    # Event handlers:
    #

    def leased_ipv4_address(item, params)
      ip_lease = MW::IpLease.batch[params[:ip_lease_id]].commit(:fill => [:interface, :ip_address])

      return if ip_lease.interface_id != item.id
      return if ip_lease.interface.nil?

      network = @dp_info.network_manager.item(id: ip_lease.interface.network_id)

      item.add_ipv4_address(mac_address: item.mac_address,
                            network_id: network[:id],
                            network_type: network[:type],
                            ip_lease_id: ip_lease.id,
                            ipv4_address: IPAddr.new(ip_lease.ip_address.ipv4_address, Socket::AF_INET))
    end

    def released_ipv4_address(item, params)
      ip_lease = MW::IpLease.batch[params[:ip_lease_id]].commit(:fill => [:interface, :ip_address])

      return if ip_lease && ip_lease.interface_id == item.id

      item.remove_ipv4_address(ip_lease_id: params[:ip_lease_id])
    end

  end

end
