# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TunnelManager < Vnet::Openflow::Manager
    include Vnet::Openflow::FlowHelpers
    include Vnet::UpdatePropertyStates

    #
    # Events:
    #
    subscribe_event REMOVED_TUNNEL, :unload
    subscribe_event INITIALIZED_TUNNEL, :install_item

    subscribe_event TUNNEL_UPDATE_PROPERTY_STATES, :update_property_states

    subscribe_event ADDED_HOST_DATAPATH_NETWORK, :added_host_datapath_network
    subscribe_event ADDED_REMOTE_DATAPATH_NETWORK, :added_remote_datapath_network
    subscribe_event ADDED_HOST_DATAPATH_ROUTE_LINK, :added_host_datapath_route_link
    subscribe_event ADDED_REMOTE_DATAPATH_ROUTE_LINK, :added_remote_datapath_route_link
    subscribe_event REMOVED_HOST_DATAPATH_NETWORK, :removed_host_datapath_network
    subscribe_event REMOVED_REMOTE_DATAPATH_NETWORK, :removed_remote_datapath_network
    subscribe_event REMOVED_HOST_DATAPATH_ROUTE_LINK, :removed_host_datapath_route_link
    subscribe_event REMOVED_REMOTE_DATAPATH_ROUTE_LINK, :removed_remote_datapath_route_link

    def initialize(*args)
      super
      @interfaces = {}

      @host_networks = {}
      @host_route_links = {}
      @remote_datapath_networks = {}
      @remote_datapath_route_links = {}
    end

    def update(params)
      case params[:event]
      when :set_tunnel_port_number
        set_tunnel_port_number(params)
      when :updated_interface
        updated_interface(params)
      end

      nil
    end

    def delete_all_tunnels
      @items.values.each { |item| unload(id: item.id) }
      nil
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
      # return false if params[:mode] && params[:mode] != item.mode
      return false if params[:port_name] && params[:port_name] != item.display_name
      return false if params[:dst_datapath_id] && params[:dst_datapath_id] != item.dst_datapath_id
      return false if params[:src_interface_id] && params[:src_interface_id] != item.src_interface_id
      return false if params[:dst_interface_id] && params[:dst_interface_id] != item.dst_interface_id
      true
    end

    def select_filter_from_params(params)
      return nil if @datapath_info.nil?

      return params if params.keys == [:src_datapath_id, :dst_datapath_id,
                                       :src_interface_id, :dst_interface_id]

      # Ensure to update tunnel items only belonging to this
      { src_datapath_id: @datapath_info.id }.tap do |options|
        case
        when params[:id]              then options[:id] = params[:id]
        when params[:uuid]            then options[:uuid] = params[:uuid]
        # when params[:mode]            then options[:mode] = params[:mode]
        when params[:port_name]       then options[:display_name] = params[:port_name]

        when params[:dst_datapath_id]  then options[:dst_datapath_id] = params[:dst_datapath_id]
        when params[:dst_interface_id] then options[:dst_interface_id] = params[:dst_interface_id]
        when params[:src_interface_id] then options[:src_interface_id] = params[:src_interface_id]

        else
          # Any invalid params that should cause an exception needs to
          # be caught by the item_by_params_direct method.
          return nil
        end
      end
    end

    def select_tunnel_mode(src_interface_id, dst_interface_id)
      src_interface = @interfaces[src_interface_id]
      dst_interface = @interfaces[dst_interface_id]
      return :unknown unless src_interface && src_interface[:network_id]
      return :unknown unless dst_interface && dst_interface[:network_id]

      case
      when src_interface[:network_id] != dst_interface[:network_id]
        :gre
      when src_interface[:network_id] == dst_interface[:network_id]
        :mac2mac
      else
        nil
      end
    end

    def items_with_src_interface(interface_id)
      @items.select { |id, item|
        item.src_interface_id == interface_id
      }
    end

    def items_with_dst_interface(interface_id)
      @items.select { |id, item|
        item.dst_interface_id == interface_id
      }
    end

    #
    # Create / Delete tunnels:
    #

    # The tunnel mode is decided by the tunnel manager based on the
    # source and destination interfaces, and the db updated in
    # the install event.
    #
    # If we cannot determine the type of tunnel to use, an unknown
    # item type is created that will reload itself when the right
    # tunnel mode has been determined.
    def item_initialize(item_map, params)
      tunnel_mode = select_tunnel_mode(item_map.src_interface_id, item_map.dst_interface_id)

      item_class =
        case tunnel_mode
        when :gre     then Tunnels::Gre
        when :mac2mac then Tunnels::Mac2Mac
        when :unknown then Tunnels::Unknown
        else
          return
        end

      item_class.new(dp_info: @dp_info,
                     manager: self,
                     map: item_map)
    end

    def initialized_item_event
      INITIALIZED_TUNNEL
    end

    def update_property_states_event
      TUNNEL_UPDATE_PROPERTY_STATES
    end

    def select_item(filter)
      MW::Tunnel.batch[filter].commit
    end
    
    def install_item(params)
      item_map = params[:item_map] || return
      item = (item_map.id && @items[item_map.id]) || return

      debug log_format("install #{item.mode} #{item.uuid}/#{item.id}",
                       "src_interface_id:#{item.src_interface_id} dst_interface_id:#{item.dst_interface_id}")
      
      # TODO: If item_map and item.mode are different (and not unknown), update db.
      tunnel_mode = select_tunnel_mode(item.src_interface_id, item.dst_interface_id)
      return reload_item(item) if tunnel_mode != item.mode

      setup_item(item, item_map, params)
    end

    def setup_item(item, item_map, params)
      item.update_mode(item.mode) if item_map.mode != item.mode
      item.try_install

      # TODO: If item type is unknown, trigger reload if we got interfaces:

      # Make these not do anything when not installed:
      dst_interface = @interfaces[item.dst_interface_id]
      src_interface = @interfaces[item.src_interface_id]

      item.set_dst_ipv4_address(dst_interface[:network_id], dst_interface[:ipv4_address]) if dst_interface
      item.set_src_ipv4_address(src_interface[:network_id], src_interface[:ipv4_address]) if src_interface
      item.set_host_port_number(src_interface[:port_number], {}) if src_interface

      # Should be an event that is exclusive for dpn updates (?):
      remote_dpns = @remote_datapath_networks.select { |id, remote_dpn|
        remote_dpn[:datapath_id] == item.dst_datapath_id && remote_dpn[:interface_id] == item.dst_interface_id
      }
      remote_dpns.each { |id, remote_dpn|
        item.add_datapath_network(remote_dpn)
      }

      remote_dprls = @remote_datapath_route_links.select { |id, remote_dprl|
        remote_dprl[:datapath_id] == item.dst_datapath_id && remote_dprl[:interface_id] == item.dst_interface_id
      }
      remote_dprls.each { |id, remote_dprl|
        item.add_datapath_route_link(remote_dprl)
      }

      add_dpn_hash_to_updated_networks(remote_dpns)

      # Make sure we have the remote host interface loaded.
      @dp_info.interface_manager.async.retrieve(id: item.dst_interface_id)
    end

    def delete_item(item)
      item = @items.delete(item.id)
      return unless item

      debug log_format("delete #{item.uuid}/#{item.id}")

      # interface_set_host_port_number(item.id, port_number: nil)
      item.try_uninstall

      MW::Tunnel.batch.destroy(item.uuid).commit
    end

    def reload_item(old_item)
      debug log_format("reloading #{old_item.mode} #{old_item.uuid}/#{old_item.id}")

      # interface_set_host_port_number(old_item.id, port_number: nil)
      old_item.try_uninstall

      @items.delete(old_item.id)

      item_map = MW::Tunnel.batch[old_item.id].commit || return
      return if @items[item_map.id]

      params = {}

      @items[item_map.id] = new_item = item_initialize(item_map, params)
      setup_item(new_item, item_map, params)
    end

    #
    # Network events:
    #

    # Requires queue ':update_networks'.
    def update_property_state(property_type, network_id)
      return unless property_type == :update_networks

      tunnel_actions = [:tunnel_id => network_id | TUNNEL_FLAG_MASK]
      segment_actions = []

      @items.each { |item_id, item|
        item.actions_append_flood(network_id, tunnel_actions, segment_actions)
      }

      flows = []
      
      # TODO: Change this into using a specific method to remove a network id?
      
      if tunnel_actions.size > 1
        flows << flow_create(:default,
                             table: TABLE_FLOOD_TUNNELS,
                             goto_table: TABLE_FLOOD_SEGMENT,
                             priority: 1,
                             match_network: network_id,
                             actions: tunnel_actions,
                             cookie: network_id | COOKIE_TYPE_NETWORK)
      else
        @dp_info.del_flows(table_id: TABLE_FLOOD_TUNNELS,
                           cookie: network_id | COOKIE_TYPE_NETWORK,
                           cookie_mask: COOKIE_MASK)
      end

      if !segment_actions.empty?
        flows << flow_create(:default,
                             table: TABLE_FLOOD_SEGMENT,
                             priority: 1,
                             match_network: network_id,
                             actions: segment_actions,
                             cookie: network_id | COOKIE_TYPE_NETWORK)
      else
        @dp_info.del_flows(table_id: TABLE_FLOOD_SEGMENT,
                           cookie: network_id | COOKIE_TYPE_NETWORK,
                           cookie_mask: COOKIE_MASK)
      end

      @dp_info.add_flows(flows)
    end

    #
    # Tunnel events:
    #

    def create_tunnel(options, tunnel_mode)
      # Create separate method...
      #
      # Consider adding an event for doing create?
      info log_format("creating tunnel entry mode '#{tunnel_mode}'",
                      options.map { |k, v| "#{k}:#{v}" }.join(" "))

      tunnel = MW::Tunnel.create(options.merge(mode: tunnel_mode))

      item_by_params(options)
    end

    # Load or create the tunnel item if we have both host and remote
    # datapath networks.
    #
    #
    def activate_link(host_dpn, remote_dpn, network_id)
      options = {
        src_datapath_id: @datapath_info.id,
        dst_datapath_id: remote_dpn[:datapath_id],
        src_interface_id: host_dpn[:interface_id],
        dst_interface_id: remote_dpn[:interface_id],
      }

      # TODO: Update log output:
      info log_format(
        "activated link",
        "remote_dpn:#{remote_dpn[:id]} " +
        "datapath_id:#{remote_dpn[:datapath_id]} " +
        "network_id:#{remote_dpn[:network_id]} " +
        "interface_id:#{remote_dpn[:interface_id]}"
      )

      # debug log_format("XXXXXXXXXXXX HOST: ", "#{host_dpn.inspect}")
      # debug log_format("XXXXXXXXXXXX REMO: ", "#{remote_dpn.inspect}")

      item = item_by_params(options)
      tunnel_mode = select_tunnel_mode(host_dpn[:interface_id], remote_dpn[:interface_id])

      if tunnel_mode == nil
        info log_format("cannot determine tunnel mode")
        @dp_info.interface_manager.async.retrieve(id: remote_dpn[:interface_id])

        return
      end

      # TODO: This needs to be turned into an event for tunnel creation.

      # Only do create_tunnel and return...
      item = item || create_tunnel(options, tunnel_mode)

      # Verify tunnel mode here... Rather update tunnel mode as needed.
      if tunnel_mode != item.mode
        info log_format("changing tunnel mode to #{tunnel_mode} NOT IMPLEMENTED")

        return
      end

      # We make sure not to yield before the dpn has been added to
      # item.
      item.add_datapath_network(remote_dpn)

      add_property_id_to_update_queue(:update_networks, network_id)
    end

    def deactivate_link(host_dpn, remote_dpn, network_id)
      options = {
        src_datapath_id: @datapath_info.id,
        dst_datapath_id: remote_dpn[:datapath_id],
        src_interface_id: host_dpn[:interface_id],
        dst_interface_id: remote_dpn[:interface_id],
      }

      item = internal_detect(options) || return

      info log_format(
        "deactivated link",
        "remote_dpn:#{remote_dpn[:id]} " +
        "datapath_id:#{remote_dpn[:datapath_id]} " +
        "network_id:#{remote_dpn[:network_id]} " +
        "interface_id:#{remote_dpn[:interface_id]}"
      )

      item.remove_datapath_network(remote_dpn[:id])

      add_property_id_to_update_queue(:update_networks, network_id)

      # TODO: Add event to check if item should be unloaded. Currently
      # done here:
      item.unused? && publish(REMOVED_TUNNEL, id: item.id)
    end

    def set_tunnel_port_number(params)
      port_name = params[:port_name] || return
      port_number = params[:port_number] || return

      item = item_by_params(uuid: port_name)

      if item.nil?
        info log_format("could not find tunnel item for port name '#{port_name}'")

        # Either delete the tunnel or do something else.
        return
      end

      # TODO: Turn into an event, and use the same update_networks
      # list for all callers, with an event that pulls network id's to
      # update from the list.

      updated_networks = {}
      item.set_tunnel_port_number(port_number, updated_networks)

      add_property_ids_to_update_queue(:update_networks, updated_networks.keys)
    end

    def clear_tunnel_port_number(params)
      port_name = params[:port_name] || return
      item = item_by_params(uuid: port_name) || return

      # TODO: Turn into an event, and use the same update_networks
      # list for all callers, with an event that pulls network id's to
      # update from the list.

      updated_networks = {}
      item.set_tunnel_port_number(updated_networks)

      add_property_ids_to_update_queue(:update_networks, updated_networks.keys)

      # TODO: Consider deleting here?
    end

    #
    # Interface events:
    #

    # TODO: Use the :interface event queue.

    def updated_interface(params)
      interface_id = params[:interface_id] || return
      interface_event = params[:interface_event] || return

      case interface_event
      when :added_ipv4_address
        interface_added_ipv4_address(interface_id, params)
      when :removed_ipv4_address
        interface = @interfaces.delete(interface_id)

        return if interface.nil?
        
        # Do stuff/event...

      when :set_host_port_number
        interface_set_host_port_number(interface_id, params)
      else
        error log_format("unknown updated_interface event '#{interface_event}'")
      end
    end

    def interface_prepare(interface_id, interface_mode)
      interface = @interfaces[interface_id] ||= {
        :mode => interface_mode,
        :ipv4_address => nil,
        :port_number => nil,
      }
      (interface[:mode] == interface_mode) ? interface : nil
    end

    def interface_added_ipv4_address(interface_id, params)
      interface_mode = params[:interface_mode]

      if interface_mode != :host && interface_mode != :remote
        error log_format("updated_interface received unknown interface_mode '#{interface_mode}'")
        return
      end

      debug log_format("#{interface_mode} interface #{interface_id} added ipv4 address",
                       "network_id:#{params[:network_id]} ipv4_address:#{params[:ipv4_address]}")

      # If already exists, clean up instead.
      interface = interface_prepare(interface_id, interface_mode) || return

      # Check if interface mode matches...

      interface[:network_id] = params[:network_id]
      interface[:ipv4_address] = params[:ipv4_address]

      case interface_mode
      when :host
        items_with_src_interface(interface_id).each { |id, item|
          # Register this as an event instead, and use the values in
          # '@interfaces' when handling the event.
          item.set_src_ipv4_address(interface[:network_id], interface[:ipv4_address])
          reload_item(item) if select_tunnel_mode(item.src_interface_id, item.dst_interface_id)
        }
      when :remote
        items_with_dst_interface(interface_id).each { |id, item|
          # Register this as an event instead, and use the values in
          # '@interfaces' when handling the event.
          item.set_dst_ipv4_address(interface[:network_id], interface[:ipv4_address])
          reload_item(item) if select_tunnel_mode(item.src_interface_id, item.dst_interface_id)
        }
      end
    end

    def interface_set_host_port_number(interface_id, params)
      port_number = params[:port_number] || return
      interface = interface_prepare(interface_id, :host) || return

      debug log_format("interface #{interface_id} set host port number #{port_number}")
      
      # TODO: Instead use a hash held by manager so that we avoid
      # unneeded calls to update.

      updated_networks = {}

      # A port number has already been set, handle this properly:
      if interface[:port_number]
      end

      interface[:port_number] = port_number

      items_with_src_interface(interface_id).each { |id, item|
        # Register this as an event instead, and use the values in
        # '@interfaces' when handling the event.
        item.set_host_port_number(port_number, updated_networks)
      }

      add_property_ids_to_update_queue(:update_networks, updated_networks.keys)
    end

    #
    # Datapath network events:
    #

    # ADDED_HOST_DATAPATH_NETWORK on queue ':datapath_network'
    def added_host_datapath_network(params)
      host_dpn = create_dp_obj(:host_network, params) || return
      network_id = host_dpn[:network_id]

      # Reorder so that we activate in the order of loading
      # internally, database and then create.
      remote_dpns = @remote_datapath_networks.select { |id, remote_dpn|
        remote_dpn[:network_id] == network_id
      }
      remote_dpns.each { |id, remote_dpn|
        activate_link(host_dpn, remote_dpn, network_id)
      }
    end

    # ADDED_REMOTE_DATAPATH_NETWORK on queue ':datapath_network'
    def added_remote_datapath_network(params)
      remote_dpn = create_dp_obj(:remote_network, params) || return
      network_id = remote_dpn[:network_id]

      host_dpn = @host_networks[network_id]

      activate_link(host_dpn, remote_dpn, network_id) if host_dpn
    end

    # REMOVED_HOST_DATAPATH_NETWORK on queue ':datapath_network'
    def removed_host_datapath_network(params)
      dpn_obj = params[:dp_obj] || return
      network_id = dpn_obj[:network_id] || return

      host_dpn = @host_networks.delete(network_id) || return

      debug log_format("host datapath network #{host_dpn[:id]} removed for datapath #{host_dpn[:datapath_id]}")

      # Reorder so that we activate in the order of loading
      # internally, database and then create.
      remote_dpns = @remote_datapath_networks.select { |id, remote_dpn|
        remote_dpn[:network_id] == network_id
      }
      remote_dpns.each { |id, remote_dpn|
        deactivate_link(host_dpn, remote_dpn, network_id)
      }
    end

    # REMOVED_REMOTE_DATAPATH_NETWORK on queue ':datapath_network'
    def removed_remote_datapath_network(params)
      dpn_obj = params[:dp_obj] || return
      dpn_id = dpn_obj[:id] || return
      network_id = dpn_obj[:network_id] || return

      host_dpn = @host_networks[network_id]
      remote_dpn = @remote_datapath_networks.delete(dpn_id) || return

      debug log_format("remote datapath network #{dpn_id} removed for datapath #{remote_dpn[:datapath_id]}")

      deactivate_link(host_dpn, remote_dpn, network_id) if host_dpn
    end

    #
    # Datapath route_link events:
    #

    # ADDED_HOST_DATAPATH_ROUTE_LINK on queue ':datapath_route_link'
    def added_host_datapath_route_link(params)
      host_dprl = create_dp_obj(:host_route_link, params) || return
      route_link_id = host_dprl[:route_link_id]

      # Reorder so that we activate in the order of loading
      # internally, database and then create.
      remote_dprls = @remote_datapath_route_links.select { |id, remote_dprl|
        remote_dprl[:route_link_id] == route_link_id
      }
      remote_dprls.each { |id, remote_dprl|
        activate_link(host_dprl, remote_dprl, route_link_id)
      }
    end

    # ADDED_REMOTE_DATAPATH_ROUTE_LINK on queue ':datapath_route_link'
    def added_remote_datapath_route_link(params)
      remote_dprl = create_dp_obj(:remote_route_link, params) || return
      route_link_id = remote_dprl[:route_link_id]

      host_dprl = @host_route_links[route_link_id]

      activate_link(host_dprl, remote_dprl, route_link_id) if host_dprl
    end

    #
    # Helper methods:
    #

    def create_dp_obj(type, params)
      case type
      when :host_network
        dst_list, dst_log_prefix = @host_networks, "host datapath network"
        dst_key_type = dst_object_type = :network_id
      when :remote_network
        dst_list, dst_log_prefix = @remote_datapath_networks, "remote datapath network"
        dst_key_type, dst_object_type = :id, :network_id
      when :host_route_link
        dst_list, dst_log_prefix = @host_route_links, "host datapath route link"
        dst_key_type = dst_object_type = :route_link_id
      when :remote_route_link
        dst_list, dst_log_prefix = @remote_datapath_route_links, "remote datapath route link"
        dst_key_type, dst_object_type = :id, :route_link_id
      end

      param_obj = params[:dp_obj] || return
      key_id = param_obj[dst_key_type] || return

      id = param_obj[:id] || return
      object_id = param_obj[dst_object_type] || return
      datapath_id = param_obj[:datapath_id] || return
      interface_id = param_obj[:interface_id] || return
      mac_address = param_obj[:mac_address] || return

      if dst_list[key_id]
        error log_format("#{dst_log_prefix} #{key_id} already added")
        return
      end

      debug log_format("#{dst_log_prefix} #{key_id} added for datapath #{datapath_id}",
                       "#{dst_object_type}:#{object_id} interface_id:#{interface_id} mac_address:#{mac_address}")

      dst_list[key_id] = {
        :id => id,
        :datapath_id => datapath_id,
        dst_object_type => object_id,
        :interface_id => interface_id,
        :mac_address => mac_address
      }
    end

    def add_dpn_hash_to_updated_networks(dpns)
      dpns.map { |id, remote_dpns|
        remote_dpns[:network_id]
      }.tap { |network_ids|
        add_property_ids_to_update_queue(:update_networks, network_ids)
      }
    end

  end

end
