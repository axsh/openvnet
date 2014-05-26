# -*- coding: utf-8 -*-

module Vnet::Openflow

  class InterfaceManager < Vnet::Openflow::Manager
    include ActivePorts

    #
    # Events:
    #
    subscribe_event INTERFACE_INITIALIZED, :load_item
    subscribe_event INTERFACE_UNLOAD_ITEM, :unload_item
    subscribe_event INTERFACE_CREATED_ITEM, :create_item
    subscribe_event INTERFACE_DELETED_ITEM, :unload_item

    subscribe_event INTERFACE_ACTIVATE_PORT, :activate_port
    subscribe_event INTERFACE_DEACTIVATE_PORT, :deactivate_port

    subscribe_event INTERFACE_UPDATED, :update_item_exclusively
    subscribe_event INTERFACE_ENABLED_FILTERING, :enabled_filtering
    subscribe_event INTERFACE_DISABLED_FILTERING, :disabled_filtering
    subscribe_event INTERFACE_REMOVE_ALL_ACTIVE_DATAPATHS, :remove_all_active_datapaths

    subscribe_event INTERFACE_LEASED_MAC_ADDRESS, :leased_mac_address
    subscribe_event INTERFACE_RELEASED_MAC_ADDRESS, :released_mac_address
    subscribe_event INTERFACE_LEASED_IPV4_ADDRESS, :leased_ipv4_address
    subscribe_event INTERFACE_RELEASED_IPV4_ADDRESS, :released_ipv4_address

    def load_internal_interfaces
      return if @datapath_info.nil?

      internal_load_where(mode: 'internal', owner_datapath_id: @datapath_info.id)
    end

    def load_simulated_on_network_id(network_id)
      # TODO: Add list of active network id's for which we should have
      # simulated interfaces loaded.

      batch = MW::IpLease.batch.dataset.where_network_id(network_id)
      batch = batch.where_interface_mode('simulated')

      batch.all_interface_ids.commit.each { |item_id|
        item_by_params(id: item_id)
      }
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

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid, :mode, :port_name, :port_number
        proc { |id, item| value == item.send(filter) }
      when :owner_datapath_id
        proc { |id, item|
          next true if value.nil? && item.owner_datapath_ids
          next true if value && item.owner_datapath_ids.nil?
          next true if value && item.owner_datapath_ids.find_index(value).nil?
          false
        }
      when :allowed_datapath_id
        proc { |id, item|
          next true if value.nil?
          next true if item.owner_datapath_ids && item.owner_datapath_ids.find_index(value).nil?
          false
        }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {mode: params[:mode]} if params.has_key? :mode
      filter << {port_name: params[:port_name]} if params.has_key? :port_name
      filter << {owner_datapath_id: params[:owner_datapath_id]} if params.has_key? :owner_datapath_id

      if params.has_key? :allowed_datapath_id
        filter << Sequel.|({ owner_datapath_id: nil },
                           { owner_datapath_id: params[:allowed_datapath_id] })
      end

      filter
    end

    def item_initialize(item_map, params)
      mode = (item_map.mode && item_map.mode.to_sym)

      if mode == :vif
        mode = :remote if is_assigned_remotely?(item_map)
      elsif is_remote?(item_map)
        mode = :remote
      end

      item_class =
        case mode
        when :edge      then Interfaces::Edge
        when :host      then Interfaces::Host
        when :internal  then Interfaces::Internal
        when :patch     then Interfaces::Patch
        when :remote    then Interfaces::Remote
        when :simulated then Interfaces::Simulated
        when :vif       then Interfaces::Vif
        else
          Interfaces::Base
        end

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete interfaces:
    #

    def item_pre_install(item, item_map)
      if item.port_name
        @active_ports.detect { |port_number, active_port|
          item.port_name == active_port[:port_name]
        }.tap { |port_number, active_port|
          next unless port_number && active_port

          item.update_port_number(port_number)

          @dp_info.port_manager.publish(PORT_ATTACH_INTERFACE,
                                        id: item.port_number,
                                        interface: item_to_hash(item))
        }
      end
    end

    def item_post_install(item, item_map)
      load_addresses(item_map)

      return if item.mode == :remote

      @dp_info.tunnel_manager.publish(TRANSLATION_ACTIVATE_INTERFACE,
                                      id: :interface,
                                      interface_id: item.id)

      item.ingress_filtering_enabled &&
        @dp_info.filter_manager.async.apply_filters(item_map)

      return unless @datapath_info

      update_active_datapath(item, @datapath_info.id)
    end

    def item_post_uninstall(item)
      if (item.owner_datapath_ids &&
          item.owner_datapath_ids.include?(@datapath_info.id)) || item.port_number
        update_active_datapath(item, nil)
      end

      if item.mode != :remote
        item.port_number &&
          @dp_info.port_manager.publish(PORT_DETACH_INTERFACE,
                                        id: item.port_number,
                                        interface_id: item.id)

        @dp_info.tunnel_manager.publish(TRANSLATION_DEACTIVATE_INTERFACE,
                                        id: :interface,
                                        interface_id: item.id)

        @dp_info.filter_manager.async.remove_filters(item.id)

        item.mac_addresses.each { |id, mac|
          @dp_info.connection_manager.async.remove_catch_new_egress(id)
          @dp_info.connection_manager.async.close_connections(id)
        }
      end
    end

    def create_item(params)
      return if @items[params[:id]]

      return unless @dp_info.port_manager.detect(port_name: params[:port_name])

      self.retrieve(params)
    end

    #
    # Helper methods:
    #

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
                mac_lease_id: mac_lease.id,
                mac_address: mac_lease.mac_address)

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
        @dp_info.network_manager.detect(id: ip_lease.ip_address.network_id)

        @dp_info.interface_manager.retrieve(id: ip_lease.interface.id)

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

    #
    # Update events:
    #

    # INTERFACE_REMOVE_ALL_ACTIVE_DATAPATHS on queue '???'
    def remove_all_active_datapaths(params)
      # TODO: Make sure we don't set active datapath for items
      # installed after this call.
      @items.keys.each do |item_id|
        publish(INTERFACE_UPDATED, event: :active_datapath_id, id: item_id, datapath_id: nil)
      end
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
        update_active_datapath(item, params[:datapath_id])

      when :remote_datapath_id
        item.update_remote_datapath(params)

        if params[:datapath_id].nil?
          @items.values.each do |item|
            item.del_flows_for_active_datapath(params[:ipv4_addresses])
          end
        end

      when :owner_datapath_id
        unload_item(id: item.id)
        self.async.retrieve(id: item.id)

        #
        # Port events:
        #
      when :set_port_number
        debug log_format("update_item", params)

        item.update_port_number(params[:port_number])
        update_active_datapath(item, @datapath_info.id)

        @dp_info.port_manager.publish(PORT_ATTACH_INTERFACE,
                                      id: item.port_number,
                                      interface: item_to_hash(item))

      when :clear_port_number
        debug log_format("update_item", params)

        @dp_info.port_manager.publish(PORT_DETACH_INTERFACE,
                                      id: item.port_number,
                                      interface: item_to_hash(item))

        # Check if nil... (use param :port_number to verify)
        item.update_port_number(nil)
        update_active_datapath(item, nil)

        #
        # Capability events:
        #
      when :updated
        # api event
        item.update
      end
    end

    def update_active_datapath(item, datapath_id)
      return if item.mode == :remote

      if item.owner_datapath_ids.nil?
        return unless item.mode == :vif
      else
        return unless item.owner_datapath_ids.include?(@datapath_info.id)
      end

      item.update_active_datapath(@datapath_info.id)
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

    #
    # Overload helper methods:
    #

    def activate_port_query(state_id, params)
      { port_name: params[:port_name],
        allowed_datapath_id: @datapath_info.id
      }
    end

    def activate_port_match_proc(state_id, params)
      port_name = params[:port_name]

      Proc.new { |id, item|
        item.mode != :remote &&
        item.port_name == port_name
      }
    end

    def activate_port_value(port_number, params)
      port_name = params[:port_name] || return

      { port_name: port_name }
    end

    def activate_port_update_item_proc(port_number, params)
      port_name = params[:port_name] || return

      Proc.new { |id, item|
        item.port_name = port_name

        publish(INTERFACE_UPDATED,
                event: :set_port_number,
                id: id,
                port_number: port_number)
      }
    end

  end

end
