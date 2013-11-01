# -*- coding: utf-8 -*-

module Vnet::Openflow

  class InterfaceManager < Manager

    #
    # Events:
    #
    subscribe_event ADDED_INTERFACE, :item
    subscribe_event REMOVED_INTERFACE, :delete_item
    subscribe_event INITIALIZED_INTERFACE, :create_item
    subscribe_event LEASED_IPV4_ADDRESS, :leased_ipv4_address
    subscribe_event RELEASED_IPV4_ADDRESS, :released_ipv4_address
    subscribe_event LEASED_MAC_ADDRESS, :leased_mac_address
    subscribe_event RELEASED_MAC_ADDRESS, :released_mac_address

    def update_item(params)
      # Todo: Add the possibility to use a 'filter' parameter for this.
      item = item_by_params(params)
      return nil if item.nil?

      case params[:event]
      when :active_datapath_id
        # Reconsider this...
        item.update_active_datapath(params)
      when :set_port_number
        # Check if not nil...
        item.update_port_number(params[:port_number])
        item.update_active_datapath(datapath_id: @datapath_info.id)
      when :clear_port_number
        # Check if nil... (use param :port_number to verify)
        item.update_port_number(nil)
        item.update_active_datapath(datapath_id: nil)
      when :enable_router_ingress
        item.enable_router_ingress
      end

      item_to_hash(item)
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
      return false if params[:port_name] && params[:port_name] != item.port_name
      true
    end

    def select_filter_from_params(params)
      case
      when params[:id]   then {:id => params[:id]}
      when params[:uuid] then params[:uuid]
      when params[:port_name] then
        { :port_name => params[:port_name] }
      else
        # Any invalid params that should cause an exception needs to
        # be caught by the item_by_params_direct method.
        return nil
      end
    end

    def item_initialize(item_map, params)
      mode = is_remote?(item_map) ? :remote : item_map.mode.to_sym
      params = { dp_info: @dp_info,
                 manager: self,
                 map: item_map }

      case mode
      when :simulated then Interfaces::Simulated.new(params)
      when :remote then Interfaces::Remote.new(params)
      when :vif then Interfaces::Vif.new(params)
      when :edge then Interfaces::Edge.new(params)
      else
        Interfaces::Base.new(params)
      end
    end

    def initialized_item_event
      CreatedlInterface
    end

    def select_item(filter)
      # Using fill for ip_leases/ip_addresses isn't going to give us a
      # proper event barrier.
      #
      # To avoid a deadlock issue when retriving network type during
      # load_addresses, we load the network here.

      fill = [:mac_leases => [:cookie_id, :ip_leases => [:cookie_id, :ip_address, :network]],
              :ip_leases => [:cookie_id, :ip_address, :network]]              

      MW::Interface.batch[filter].commit(:fill => fill)
    end

    #
    # Create / Delete interfaces:
    #

    def create_item(item_map, params)
      item = @items[item_map.id]
      return nil if item.nil?

      debug log_format("create #{item_map.uuid}/#{item_map.id}", "mode:#{mode}")

      item.install

      load_addresses(item, item_map)

      item # Return nil if interface has been uninstalled.
    end

    def delete_item(item)
      @items.delete(item.id)

      item.uninstall

      if item.port_number
        item.update_active_datapath(datapath_id: nil)
      end

      item
    end

    # TODO: Convert the loading of addresses to events, and queue them
    # with a 'handle_event' queue to ensure consistency.
    def load_addresses(interface, item_map)
      return if item_map.mac_leases.empty?

      item_map.mac_leases.each do |mac_lease|
        mac_address = Trema::Mac.new(mac_lease.mac_address)
        interface.add_mac_address(mac_lease_id: mac_lease.id,
                                  mac_address: mac_address,
                                  cookie_id: mac_lease.cookie_id)

        mac_lease.ip_leases.each { |ip_lease|
          ipv4_address = ip_lease.ip_address.ipv4_address
          error log_format("ipv4_address is nil", ip_lease.uuid) unless ipv4_address

          network = ip_lease.network
          error log_format("network is nil", ip_lease.uuid) unless network

          interface.add_ipv4_address(mac_lease_id: mac_lease.id,
                                     network_id: network.id,
                                     network_type: network.network_mode.to_sym,
                                     ip_lease_id: ip_lease.id,
                                     cookie_id: ip_lease.cookie_id,
                                     ipv4_address: IPAddr.new(ipv4_address, Socket::AF_INET))
        }
      end
    end

    def is_remote?(item_map)
      return false if item_map.active_datapath_id.nil? && item_map.owner_datapath_id.nil?

      if item_map.owner_datapath_id
        return item_map.owner_datapath_id != @datapath_info.id
      end

      return false
    end

    #
    # Event handlers:
    #

    def leased_mac_address(item, params)
      mac_lease = MW::MacLease.batch[params[:mac_lease_id]].commit(fill: [:cookie_id, :interface])

      return unless mac_lease && mac_lease.interface_id == item.id

      mac_address = Trema::Mac.new(mac_lease.mac_address)
      item.add_mac_address(mac_lease_id: mac_lease.id,
                           mac_address: mac_address,
                           cookie_id: mac_lease.cookie_id)
    end

    def released_mac_address(item, params)
      mac_lease = MW::MacLease.batch[params[:mac_lease_id]].commit

      return if mac_lease && mac_lease.interface_id == item.id

      item.remove_mac_address(mac_lease_id: params[:mac_lease_id])
    end

    def leased_ipv4_address(item, params)
      ip_lease = MW::IpLease.batch[params[:ip_lease_id]].commit(:fill => [:ip_address, :cookie_id])

      return unless ip_lease && ip_lease.interface_id == item.id

      network = @dp_info.network_manager.item(id: ip_lease.ip_address.network_id)

      item.add_ipv4_address(mac_lease_id: ip_lease.mac_lease_id,
                            network_id: network[:id],
                            network_type: network[:type],
                            ip_lease_id: ip_lease.id,
                            cookie_id: ip_lease.cookie_id,
                            ipv4_address: IPAddr.new(ip_lease.ip_address.ipv4_address, Socket::AF_INET))
    end

    def released_ipv4_address(item, params)
      ip_lease = MW::IpLease.batch[params[:ip_lease_id]].commit

      return if ip_lease && ip_lease.interface_id == item.id

      item.remove_ipv4_address(ip_lease_id: params[:ip_lease_id])
    end

  end

end
