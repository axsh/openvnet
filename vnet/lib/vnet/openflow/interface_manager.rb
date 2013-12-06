# -*- coding: utf-8 -*-

module Vnet::Openflow

  class InterfaceManager < Manager

    #
    # Events:
    #
    subscribe_event ADDED_INTERFACE, :create_item
    subscribe_event REMOVED_INTERFACE, :unload
    subscribe_event INITIALIZED_INTERFACE, :install_item
    subscribe_event LEASED_IPV4_ADDRESS, :leased_ipv4_address
    subscribe_event RELEASED_IPV4_ADDRESS, :released_ipv4_address
    subscribe_event LEASED_MAC_ADDRESS, :leased_mac_address
    subscribe_event RELEASED_MAC_ADDRESS, :released_mac_address
    subscribe_event REMOVED_ACTIVE_DATAPATH, :del_flows_for_active_datapath

    def update_item(params)
      case params[:event]
      when :remove_all_active_datapath
        @items.each { |_, item| item.update_active_datapath(datapath_id: nil) }
        return
      end

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
      when :enable_router_egress
        item.enable_router_egress
      end

      item_to_hash(item)
    end

    # Deprecate this...
    def get_ipv4_address(params)
      interface = internal_detect(params)
      return nil if interface.nil?

      interface.get_ipv4_address(params)
    end

    def del_flows_for_active_datapath(params)
      internal_select(mode: :simulated).each do |item|
        item.del_flows_for_active_datapath(params[:ipv4_addresses])
      end
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

      if params.has_key? :owner_datapath_id
        return false if params[:owner_datapath_id].nil? && item.owner_datapath_ids
        return false if params[:owner_datapath_id] && item.owner_datapath_ids.nil?
        return false if params[:owner_datapath_id] && item.owner_datapath_ids.find_index(params[:owner_datapath_id]).nil?
      end

      true
    end

    def select_filter_from_params(params)
      # TODO refactoring
      case
      when params[:id]   then {:id => params[:id]}
      when params[:uuid] then params[:uuid]
      when params[:owner_datapath_id] && params[:port_name]
        {:owner_datapath_id => params[:owner_datapath_id], :port_name => params[:port_name]}
      # when params[:allowed_datapath_id] && params[:port_name]
      #   {:owner_datapath_id => params[:allowed_datapath_id], :port_name => params[:port_name]} |
      #     {:owner_datapath_id => nil, :port_name => params[:port_name]}
      when params[:port_name]
        { :port_name => params[:port_name] }
      else
        # Any invalid params that should cause an exception needs to
        # be caught by the item_by_params_direct method.
        return nil
      end
    end

    def item_initialize(item_map)
      mode = is_remote?(item_map) ? :remote : item_map.mode.to_sym
      params = { dp_info: @dp_info,
                 manager: self,
                 map: item_map }

      case mode
      when :edge then Interfaces::Edge.new(params)
      when :host then Interfaces::Host.new(params)
      when :remote then Interfaces::Remote.new(params)
      when :simulated then Interfaces::Simulated.new(params)
      when :vif then Interfaces::Vif.new(params)
      else
        Interfaces::Base.new(params)
      end
    end

    def initialized_item_event
      INITIALIZED_INTERFACE
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

    def create_item(params)
      return if @items[params[:id]]

      return unless @dp_info.port_manager.item(
        port_name: params[:port_name],
        dynamic_load: false
      )

      item = self.item(params)
      return unless item

      debug log_format("create #{item.uuid}/#{item.id}/#{item.port_name}", "mode:#{item.mode}")

      item
    end

    def install_item(params)
      item_map = params[:item_map]
      item = @items[item_map.id]
      return nil if item.nil?

      debug log_format("install #{item_map.uuid}/#{item_map.id}/#{item.port_name}", "mode:#{item.mode}")

      item.install

      if item.owner_datapath_ids &&
          item.owner_datapath_ids.include?(@datapath_info.id)
        item.update_active_datapath(datapath_id: @datapath_info.id)
      end

      load_addresses(item_map)

      @dp_info.port_manager.async.attach_interface(port_name: item.port_name)

      item # Return nil if interface has been uninstalled.
    end

    def delete_item(item)
      item = @items.delete(item.id)
      return unless item

      debug log_format("delete #{item.uuid}/#{item.id}/#{item.port_name}", "mode:#{item.mode}")

      item.del_security_groups

      item.uninstall

      if item.owner_datapath_ids && item.owner_datapath_ids.include?(@datapath_info.id) || item.port_number
        item.update_active_datapath(datapath_id: nil)
      end

      if item.port_number
        @dp_info.port_manager.async.detach_interface(port_number: item.port_number)
      end

      item
    end

    def load_addresses(item_map)
      item_map.mac_leases.each do |mac_lease|
        publish(LEASED_MAC_ADDRESS, id: item_map.id, mac_lease_id: mac_lease.id)
        mac_lease.ip_leases.each do |ip_lease|
          publish(LEASED_IPV4_ADDRESS, id: item_map.id, ip_lease_id: ip_lease.id)
        end
      end
    end

    def is_remote?(item_map)
      return item_map.owner_datapath_id && item_map.owner_datapath_id != @datapath_info.id
    end

    #
    # Event handlers:
    #

    def leased_mac_address(params)
      item = @items[params[:id]]
      return unless item

      mac_lease = MW::MacLease.batch[params[:mac_lease_id]].commit(fill: [:cookie_id, :interface])

      return unless mac_lease && mac_lease.interface_id == item.id

      mac_address = Trema::Mac.new(mac_lease.mac_address)
      item.add_mac_address(mac_lease_id: mac_lease.id,
                           mac_address: mac_address,
                           cookie_id: mac_lease.cookie_id)
    end

    def released_mac_address(params)
      item = @items[params[:id]]
      return unless item

      mac_lease = MW::MacLease.batch[params[:mac_lease_id]].commit

      return if mac_lease && mac_lease.interface_id == item.id

      item.remove_mac_address(mac_lease_id: params[:mac_lease_id])
    end

    def leased_ipv4_address(params)
      ip_lease = MW::IpLease.batch[params[:ip_lease_id]].commit(:fill => [:interface, :ip_address, :cookie_id])
      return unless ip_lease

      item = @items[params[:id]]

      if !item && ip_lease.interface.mode.to_sym == :simulated &&
        @dp_info.network_manager.item(
          id: ip_lease.ip_address.network_id,
          dynamic_load: false
        )

        @dp_info.interface_manager.item(id: ip_lease.interface.id)

        return
      end

      return unless item && ip_lease.interface_id == item.id

      network = @dp_info.network_manager.item(id: ip_lease.ip_address.network_id)

      item.add_ipv4_address(mac_lease_id: ip_lease.mac_lease_id,
                            network_id: network[:id],
                            network_type: network[:type],
                            ip_lease_id: ip_lease.id,
                            cookie_id: ip_lease.cookie_id,
                            ipv4_address: IPAddr.new(ip_lease.ip_address.ipv4_address, Socket::AF_INET))
    end

    def released_ipv4_address(params)
      item = @items[params[:id]]
      return unless item

      ip_lease = MW::IpLease.batch[params[:ip_lease_id]].commit

      return if ip_lease && ip_lease.interface_id == item.id

      item.remove_ipv4_address(ip_lease_id: params[:ip_lease_id])
    end

  end

end
