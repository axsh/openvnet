# -*- coding: utf-8 -*-

module Vnet::Openflow

  class InterfaceManager < Vnet::Manager

    #
    # Events:
    #
    subscribe_event INTERFACE_CREATED_ITEM, :create_item
    subscribe_event INTERFACE_DELETED_ITEM, :unload
    subscribe_event INTERFACE_INITIALIZED, :install_item

    subscribe_event INTERFACE_UPDATED, :update_item_exclusively
    subscribe_event INTERFACE_ENABLED_FILTERING, :enabled_filtering
    subscribe_event INTERFACE_DISABLED_FILTERING, :disabled_filtering
    subscribe_event INTERFACE_REMOVED_ACTIVE_DATAPATH, :del_flows_for_active_datapath

    subscribe_event INTERFACE_LEASED_MAC_ADDRESS, :leased_mac_address
    subscribe_event INTERFACE_RELEASED_MAC_ADDRESS, :released_mac_address
    subscribe_event INTERFACE_LEASED_IPV4_ADDRESS, :leased_ipv4_address
    subscribe_event INTERFACE_RELEASED_IPV4_ADDRESS, :released_ipv4_address

    def update_item(params)
      case params[:event]
      when :remove_all_active_datapath
        @items.each do |_, item|
          publish(INTERFACE_UPDATED, event: :active_datapath_id, id: item.id, datapath_id: nil)
        end
      else
        publish(INTERFACE_UPDATED, params)
      end
    end

    # Deprecate this...
    def get_ipv4_address(params)
      interface = internal_detect(params)
      return nil if interface.nil?

      interface.get_ipv4_address(params)
    end

    def del_flows_for_active_datapath(params)
      @items.values.each do |item|
        item.del_flows_for_active_datapath(params[:ipv4_addresses])
      end
    end

    #
    # Internal methods:
    #

    private

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
      return nil if params.has_key?(:uuid) && params[:uuid].nil?

      filters = []
      filters << {id: params[:id]} if params.has_key? :id
      filters << {owner_datapath_id: params[:owner_datapath_id]} if params.has_key? :owner_datapath_id
      filters << {port_name: params[:port_name]} if params.has_key? :port_name

      create_batch(MW::Interface.batch, params[:uuid], filters)
    end

    def item_initialize(item_map, params)
      if params[:remote]
        return if !is_assigned_remotely?(item_map)
        mode = :remote
      elsif is_remote?(item_map)
        mode = :remote
      else
        mode = (item_map.mode && item_map.mode.to_sym)
      end

      item_class =
        case mode
        when :edge      then Interfaces::Edge
        when :host      then Interfaces::Host
        when :remote    then Interfaces::Remote
        when :patch     then Interfaces::Patch
        when :simulated then Interfaces::Simulated
        when :vif       then Interfaces::Vif
        else
          Interfaces::Base
        end

      item_class.new(
        dp_info: @dp_info,
        manager: self,
        map: item_map
      )
    end

    def initialized_item_event
      INTERFACE_INITIALIZED
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

      self.retrieve(params)
    end

    def install_item(params)
      item_map = params[:item_map] || return
      item = (item_map.id && @items[item_map.id]) || return

      debug log_format("install #{item_map.uuid}/#{item_map.id}/#{item.port_name}", "mode:#{item.mode}")

      item.install

      if item.owner_datapath_ids &&
          item.owner_datapath_ids.include?(@datapath_info.id)
        item.update_active_datapath(datapath_id: @datapath_info.id)
      end

      load_addresses(item_map)

      if item.mode != :remote
        @dp_info.port_manager.async.attach_interface(port_name: item.port_name)

        @dp_info.tunnel_manager.async.publish(Vnet::Event::TRANSLATION_ACTIVATE_INTERFACE,
                                              id: :interface,
                                              interface_id: item.id)

        item.ingress_filtering_enabled &&
          @dp_info.filter_manager.async.apply_filters(item_map)
      end
    end

    def delete_item(item)
      item = @items.delete(item.id) || return

      debug log_format("delete #{item.uuid}/#{item.id}/#{item.port_name}", "mode:#{item.mode}")

      item.uninstall

      if item.owner_datapath_ids && item.owner_datapath_ids.include?(@datapath_info.id) || item.port_number
        item.update_active_datapath(datapath_id: nil)
      end

      if item.port_number
        @dp_info.port_manager.async.detach_interface(port_number: item.port_number)
      end

      if item.mode != :remote
        @dp_info.tunnel_manager.async.publish(Vnet::Event::TRANSLATION_DEACTIVATE_INTERFACE,
                                              id: :interface,
                                              interface_id: item.id)

        @dp_info.filter_manager.async.remove_filters(item.id)

        item.mac_addresses.each { |id, mac|
          @dp_info.connection_manager.async.remove_catch_new_egress(id)
          @dp_info.connection_manager.async.close_connections(id)
        }
      end
    end

    def is_remote?(item_map)
      return false if item_map.active_datapath_id.nil? && item_map.owner_datapath_id.nil?

      if item_map.owner_datapath_id
        return @datapath_info.nil? || item_map.owner_datapath_id != @datapath_info.id
      end

      return false
    end

    def is_assigned_remotely?(item_map)
      return @datapath_info.nil? || item_map.owner_datapath_id != @datapath_info.id if item_map.owner_datapath_id
      return @datapath_info.nil? || item_map.active_datapath_id != @datapath_info.id if item_map.active_datapath_id

      false
    end

    #
    # Event handlers:
    #

    # load addresses on queue 'item.id'
    def load_addresses(item_map)
      # Using fill for ip_leases/ip_addresses isn't going to give us a
      # proper event barrier.
      #
      # To avoid a deadlock issue when retriving network type during
      # load_addresses, we load the network here.
      mac_leases = item_map.batch.mac_leases.commit(fill: [:cookie_id, :ip_leases => [:cookie_id, :ip_address]])

      mac_leases.each do |mac_lease|
        publish(INTERFACE_LEASED_MAC_ADDRESS, id: item_map.id,
                                    mac_lease_id: mac_lease.id,
                                    mac_address: mac_lease.mac_address)

        mac_lease.ip_leases.each do |ip_lease|
          publish(INTERFACE_LEASED_IPV4_ADDRESS, id: item_map.id, ip_lease_id: ip_lease.id)
        end
      end
    end

    # INTERFACE_LEASED_MAC_ADDRESS on queue 'item.id'
    def leased_mac_address(params)
      item = @items[params[:id]] || return

      mac_lease = MW::MacLease.batch[params[:mac_lease_id]].commit(fill: [:cookie_id, :interface])

      return unless mac_lease && mac_lease.interface_id == item.id

      mac_address = Trema::Mac.new(mac_lease.mac_address)
      item.add_mac_address(mac_lease_id: mac_lease.id,
                           mac_address: mac_address,
                           cookie_id: mac_lease.cookie_id)

      item.ingress_filtering_enabled &&
        @dp_info.connection_manager.async.catch_new_egress(mac_lease.id, mac_address)
    end

    # INTERFACE_RELEASED_MAC_ADDRESS on queue 'item.id'
    def released_mac_address(params)
      item = @items[params[:id]] || return

      mac_lease = MW::MacLease.batch[params[:mac_lease_id]].commit

      return if mac_lease && mac_lease.interface_id == item.id

      item.remove_mac_address(mac_lease_id: params[:mac_lease_id])

      @dp_info.connection_manager.async.remove_catch_new_egress(params[:mac_lease_id])
      @dp_info.connection_manager.async.close_connections(params[:mac_lease_id])
    end

    # INTERFACE_LEASED_IPV4_ADDRESS on queue 'item.id'
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

    # INTERFACE_RELEASED_IPV4_ADDRESS on queue 'item.id'
    def released_ipv4_address(params)
      item = @items[params[:id]] || return

      ip_lease = MW::IpLease.batch[params[:ip_lease_id]].commit

      return if ip_lease && ip_lease.interface_id == item.id

      item.remove_ipv4_address(ip_lease_id: params[:ip_lease_id])
    end

    # INTERFACE_ENABLED_FILTERING on queue 'item.id'
    def enabled_filtering(params)
      item = @items[params[:id]]
      return if !item || item.ingress_filtering_enabled

      info log_format("enabled filtering on interface", item.uuid)
      item.enable_filtering
    end

    # INTERFACE_DISABLED_FILTERING on queue 'item.id'
    def disabled_filtering(params)
      item = @items[params[:id]]
      return if !item || !item.ingress_filtering_enabled

      info log_format("disabled filtering on interface", item.uuid)
      item.disable_filtering
    end

    def update_item_exclusively(params)
      id = params.fetch(:id) || return
      event = params[:event] || return

      # Todo: Add the possibility to use a 'filter' parameter for this.
      item = internal_detect(id: id)
      return update_item_not_found(event, id, params) if item.nil?

      case event
        #
        # Datapath events:
        #
      when :active_datapath_id
        # Reconsider this...
        item.update_active_datapath(params)

      when :remote_datapath_id
        item.update_remote_datapath(params)
        del_flows_for_active_datapath(params) if params[:datapath_id].nil?

      when :owner_datapath_id
        delete_item(item)
        self.async.retrieve(id: item.id)

        #
        # Port events:
        #
      when :set_port_number
        debug log_format("update_item", params)
        # Check if not nil...
        item.update_port_number(params[:port_number])
        item.update_active_datapath(datapath_id: @datapath_info.id)
      when :clear_port_number
        debug log_format("update_item", params)
        # Check if nil... (use param :port_number to verify)
        item.update_port_number(nil)
        item.update_active_datapath(datapath_id: nil)

        #
        # Capability events:
        #
      when :updated
        # api event
        item.update
      end

      item_to_hash(item)
    end

    def update_item_not_found(event, id, params)
      case event
      when :updated
        changed_columns = params[:changed_columns]
        return if changed_columns.nil?

        if changed_columns["owner_datapath_id"]
          return if changed_columns["owner_datapath_id"] != @datapath_info.id
          @dp_info.port_manager.async.attach_interface(port_name: params[:port_name])
        end
      end

      nil
    end

  end

end
