# -*- coding: utf-8 -*-

module Vnet::Core

  class InterfaceManager < Vnet::Core::Manager

    include Vnet::Constants::Interface

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event INTERFACE_INITIALIZED, :load_item
    subscribe_event INTERFACE_UNLOAD_ITEM, :unload_item
    subscribe_event INTERFACE_CREATED_ITEM, :created_item
    subscribe_event INTERFACE_DELETED_ITEM, :unload_item

    subscribe_event INTERFACE_UPDATED, :update_item_exclusively
    subscribe_event INTERFACE_ENABLED_FILTERING, :enabled_filtering
    subscribe_event INTERFACE_DISABLED_FILTERING, :disabled_filtering
    subscribe_event INTERFACE_ENABLED_FILTERING2, :enabled_filtering2
    subscribe_event INTERFACE_DISABLED_FILTERING2, :disabled_filtering2

    subscribe_event INTERFACE_LEASED_MAC_ADDRESS, :leased_mac_address
    subscribe_event INTERFACE_RELEASED_MAC_ADDRESS, :released_mac_address
    subscribe_event INTERFACE_LEASED_IPV4_ADDRESS, :leased_ipv4_address
    subscribe_event INTERFACE_RELEASED_IPV4_ADDRESS, :released_ipv4_address

    def initialize(*args)
      super
      @interface_ports = {}
    end

    # Disable retrieve...
    def retrieve(params)
      error log_format("disabled retrieve method")
      Thread.current.backtrace.each { |str| info log_format(str) }
      nil
    end

    # Disable unload... (?)

    def load_shared_interface(interface_id)
      item_to_hash(internal_retrieve(id: interface_id))
    end

    def load_local_interface(interface_id)
      item_to_hash(internal_retrieve(id: interface_id))
    end

    def load_local_port(interface_id, port_name, port_number)
      # TODO: Check if interface_id/port_number exists.
      @interface_ports[interface_id] = {
        port_name: port_name,
        port_number: port_number
      }

      item_to_hash(internal_retrieve(id: interface_id))
    end

    def unload_local_port(interface_id, port_name, port_number)
      interface_port = @interface_ports.delete(interface_id)

      # TODO: Check if port_name/port_number matches.
      publish(INTERFACE_UNLOAD_ITEM, id: interface_id)
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Interface
    end

    def initialized_item_event
      INTERFACE_INITIALIZED
    end

    def item_unload_event
      INTERFACE_UNLOAD_ITEM
    end

    # The port_name and port_number filter arguments only applies to
    # already loaded items.
    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid, :mode, :port_name, :port_number
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {mode: params[:mode]} if params.has_key? :mode
      filter
    end

    def item_initialize(item_map)
      item_class =
        case item_map.mode
        when MODE_EDGE      then Interfaces::Edge
        when MODE_HOST      then Interfaces::Host
        when MODE_INTERNAL  then Interfaces::Internal
        when MODE_PATCH     then Interfaces::Patch
        when MODE_PROMISCUOUS then Interfaces::Promiscuous
        when MODE_SIMULATED then Interfaces::Simulated
        when MODE_VIF       then Interfaces::Vif
        else
          return nil
        end

      port = @interface_ports[item_map.id]

      item_class.new(dp_info: @dp_info,
                     map: item_map,
                     port_name: port && port[:port_name],
                     port_number: port && port[:port_number])
    end

    #
    # Create / Delete interfaces:
    #

    def item_pre_install(item, item_map)
      # Should be post-install?
      activate_local_interface(item)
    end

    def item_post_install(item, item_map)
      load_addresses(item_map)

      activate_params = {
        id: :interface,
        interface_id: item.id
      }

      @dp_info.tunnel_manager.publish(ACTIVATE_INTERFACE, activate_params)
      @dp_info.filter2_manager.publish(ACTIVATE_INTERFACE, activate_params)
      @dp_info.interface_segment_manager.publish(ACTIVATE_INTERFACE, activate_params)

      item.ingress_filtering_enabled &&
        @dp_info.filter_manager.async.apply_filters(item_map)
    end

    def item_post_uninstall(item)
      deactivate_params = {
        id: :interface,
        interface_id: item.id
      }

      @dp_info.tunnel_manager.publish(DEACTIVATE_INTERFACE, deactivate_params)
      @dp_info.filter2_manager.publish(DEACTIVATE_INTERFACE, deactivate_params)
      @dp_info.interface_segment_manager.publish(DEACTIVATE_INTERFACE, deactivate_params)

      @dp_info.filter_manager.async.remove_filters(item.id)

      item.mac_addresses.each { |id, mac|
        @dp_info.connection_manager.async.remove_catch_new_egress(id)
        @dp_info.connection_manager.async.close_connections(id)
      }

      deactivate_local_interface(item)
    end

    def created_item(params)
      return if internal_detect_by_id(params)
      return unless @dp_info.port_manager.detect(port_name: params[:port_name])

      # Do nothing for now.
    end

    #
    # Helper methods:
    #

    # TODO: Change this to depend on how the interface was loaded by
    # interface_ports (or rather, move to interface_port_manager).
    def activate_local_interface(item)
      if @datapath_info.nil? || @datapath_info.uuid.nil?
        error log_format("cannot activate local interface when datapath_info.uuid is nil")
        return
      end

      case item.mode
      when :internal, :simulated
        label = @datapath_info.uuid
        singular = nil
      else
        label = nil
        singular = true
      end

      params = {
        interface_id: item.id,
        port_name: item.port_name,
        port_number: item.port_number,
        label: label,
        singular: singular,
        enable_routing: item.enable_routing
      }

      active_item = @dp_info.active_interface_manager.activate_local_item(params)
    end

    def deactivate_local_interface(item)
      @dp_info.active_interface_manager.deactivate_local_item(item.id)
    end

    #
    # Address events:
    #

    # load addresses on queue 'item.id'
    def load_addresses(item_map)
      # Using fill for ip_leases/ip_addresses isn't going to give us a
      # proper event barrier.
      #
      # To avoid a deadlock issue when retriving network type during
      # load_addresses, we load the network here.
      mac_leases = item_map.batch.mac_leases.commit(fill: [:cookie_id, :ip_leases => [:cookie_id, :ip_address]])

      mac_leases && mac_leases.each do |mac_lease|
        publish(INTERFACE_LEASED_MAC_ADDRESS,
                id: item_map.id,
                mac_lease_id: mac_lease.id)

        mac_lease.ip_leases.each do |ip_lease|
          publish(INTERFACE_LEASED_IPV4_ADDRESS,
                  id: item_map.id,
                  ip_lease_id: ip_lease.id)
        end
      end
    end

    # TODO: Use event params for lease info instead of querying the
    # db.

    # INTERFACE_LEASED_MAC_ADDRESS on queue 'item.id'
    def leased_mac_address(params)
      item = internal_detect_by_id(params) || return

      mac_lease = MW::MacLease.batch[params[:mac_lease_id]].commit(fill: [:cookie_id, :interface])

      return unless mac_lease && mac_lease.interface_id == item.id

      segment_id = mac_lease.segment_id

      # TODO: Move to interface_segment...
      if segment_id
        segment = @dp_info.segment_manager.retrieve(id: segment_id)

        if segment.nil?
          error log_format("could not find segment for mac lease",
            "interface_id:#{item.id} segment_id:#{segment_id}")
          return
        end
      end

      mac_address = Pio::Mac.new(mac_lease.mac_address)
      item.add_mac_address(mac_lease_id: mac_lease.id,
                           mac_address: mac_address,
                           segment_id: mac_lease.segment_id,
                           cookie_id: mac_lease.cookie_id)

      item.ingress_filtering_enabled &&
        @dp_info.connection_manager.async.catch_new_egress(item.id, mac_address)
    end

    # INTERFACE_RELEASED_MAC_ADDRESS on queue 'item.id'
    def released_mac_address(params)
      item = internal_detect_by_id(params) || return

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
        @dp_info.network_manager.detect(id: ip_lease.ip_address.network_id)

        @dp_info.interface_port_manager.retrieve(interface_id: ip_lease.interface.id)

        return
      end

      return unless item && ip_lease.interface_id == item.id

      network = @dp_info.network_manager.retrieve(id: ip_lease.ip_address.network_id)

      if network.nil?
        error log_format("could not find network for ip lease",
                         "interface_id:#{ip_lease.interface_id} network_id:#{ip_lease.ip_address.network_id}")
        return
      end

      # TODO: Pass the ip_lease object.
      item.add_ipv4_address(mac_lease_id: ip_lease.mac_lease_id,
                            ip_lease_id: ip_lease.id,
                            network_id: network[:id],
                            network_type: network[:type],
                            network_prefix: network[:ipv4_prefix],
                            cookie_id: ip_lease.cookie_id,
                            ipv4_address: IPAddr.new(ip_lease.ip_address.ipv4_address, Socket::AF_INET),
                            enable_routing: ip_lease.enable_routing)
    end

    # INTERFACE_RELEASED_IPV4_ADDRESS on queue 'item.id'
    def released_ipv4_address(params)
      item = internal_detect_by_id(params) || return

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

    # INTERFACE_ENABLED_FILTERING2 on queue 'item.id'
    def enabled_filtering2(params)
      item = internal_detect(id: id)
      return if !item || item.enabled_filtering

      info log_format("enabled filtering on interface", item.uuid)
      item.enable_filtering2
    end

    # INTERFACE_DISABLED_FILTERING2 on queue 'item.id'
    def disabled_filtering2(params)
      item = internal_detect(id: id)
      return if !item || !item.enabled_filtering

      info log_format("disabled filtering on interface", item.uuid)
      item.disable_filtering2
    end

    #
    # Update events:
    #

    def update_item_exclusively(params)
      id = params.fetch(:id) || return
      event = params[:event] || return

      # Todo: Add the possibility to use a 'filter' parameter for this.
      item = internal_detect(id: id)
      return if item.nil?

      case event
      when :updated
        # api event
        item.update
      end
    end

    #
    # Overload helper methods:
    #

  end

end
