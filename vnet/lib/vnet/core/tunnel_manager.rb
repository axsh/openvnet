# -*- coding: utf-8 -*-

module Vnet::Core

  class TunnelManager < Vnet::Core::Manager
    include Vnet::Openflow::FlowHelpers
    include Vnet::UpdatePropertyStates

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event REMOVED_TUNNEL, :unload
    subscribe_event INITIALIZED_TUNNEL, :install_item

    subscribe_event TUNNEL_UPDATE_PROPERTY_STATES, :update_property_states

    subscribe_event ADDED_HOST_DATAPATH_NETWORK, :added_host_datapath_network
    subscribe_event ADDED_REMOTE_DATAPATH_NETWORK, :added_remote_datapath_network
    subscribe_event REMOVED_HOST_DATAPATH_NETWORK, :removed_host_datapath_network
    subscribe_event REMOVED_REMOTE_DATAPATH_NETWORK, :removed_remote_datapath_network

    subscribe_event ADDED_HOST_DATAPATH_ROUTE_LINK, :added_host_datapath_route_link
    subscribe_event ADDED_REMOTE_DATAPATH_ROUTE_LINK, :added_remote_datapath_route_link
    subscribe_event REMOVED_HOST_DATAPATH_ROUTE_LINK, :removed_host_datapath_route_link
    subscribe_event REMOVED_REMOTE_DATAPATH_ROUTE_LINK, :removed_remote_datapath_route_link

    subscribe_event ADDED_HOST_DATAPATH_SEGMENT, :added_host_datapath_segment
    subscribe_event ADDED_REMOTE_DATAPATH_SEGMENT, :added_remote_datapath_segment
    subscribe_event REMOVED_HOST_DATAPATH_SEGMENT, :removed_host_datapath_segment
    subscribe_event REMOVED_REMOTE_DATAPATH_SEGMENT, :removed_remote_datapath_segment

    finalizer :do_cleanup

    def initialize(*args)
      super
      @interfaces = {}

      @host_networks = {}
      @host_segments = {}
      @host_route_links = {}
      @remote_datapath_networks = {}
      @remote_datapath_segments = {}
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

    #
    # Internal methods:
    #

    private

    def do_cleanup
      info log_format('cleaning up')
      @items.values.each { |item| unload(id: item.id) }
      info log_format('cleaned up')
    end

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Tunnel
    end

    def initialized_item_event
      INITIALIZED_TUNNEL
    end

    def item_unload_event
      REMOVED_TUNNEL
    end

    def update_property_states_event
      TUNNEL_UPDATE_PROPERTY_STATES
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid, :port_name, :dst_datapath_id, :src_interface_id, :dst_interface_id
        proc { |id, item| value == item.send(filter) }
      when :src_datapath_id
        proc { |id, item| true }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = [{src_datapath_id: @datapath_info.id}]

      filter << {id: params[:id]} if params.has_key? :id
      #filter << {port_name: params[:port_name]} if params.has_key? :port_name
      filter << {dst_datapath_id: params[:dst_datapath_id]} if params.has_key? :dst_datapath_id
      filter << {dst_interface_id: params[:dst_interface_id]} if params.has_key? :dst_interface_id
      filter << {src_interface_id: params[:src_interface_id]} if params.has_key? :src_interface_id
      filter
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
    def item_initialize(item_map)
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
      item.set_host_port_number(src_interface[:port_number], {}, {}) if src_interface

      # Should be an event that is exclusive for dpn updates (?):
      remote_dpns = @remote_datapath_networks.select { |id, remote_dpn|
        remote_dpn[:datapath_id] == item.dst_datapath_id && remote_dpn[:interface_id] == item.dst_interface_id
      }
      remote_dpns.each { |id, remote_dpn|
        item.add_datapath_network(remote_dpn)
      }

      remote_dpsegs = @remote_datapath_segments.select { |id, remote_dpseg|
        remote_dpseg[:datapath_id] == item.dst_datapath_id && remote_dpseg[:interface_id] == item.dst_interface_id
      }
      remote_dpsegs.each { |id, remote_dpseg|
        item.add_datapath_segment(remote_dpseg)
      }

      remote_dprls = @remote_datapath_route_links.select { |id, remote_dprl|
        remote_dprl[:datapath_id] == item.dst_datapath_id && remote_dprl[:interface_id] == item.dst_interface_id
      }
      remote_dprls.each { |id, remote_dprl|
        item.add_datapath_route_link(remote_dprl)
      }

      add_dpn_hash_to_updated_networks(remote_dpns)
      add_dpseg_hash_to_updated_segments(remote_dpsegs)
      add_dprl_hash_to_updated_route_links(remote_dprls)

      # Make sure we have the remote host interface loaded.
      # @dp_info.interface_manager.async.retrieve(id: item.dst_interface_id)
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

      @items[item_map.id] = new_item = item_initialize(item_map)
      setup_item(new_item, item_map, params)
    end

    #
    # Network events:
    #

    # Requires queue ':update_networks'.
    def update_property_state(property_type, property_id)
      flows = []

      case property_type
      when :update_networks
        tunnel_actions = [:tunnel_id => property_id | TUNNEL_FLAG_MASK]
        segment_actions = []

        @items.each { |item_id, item|
          item.actions_append_flood_network(property_id, tunnel_actions, segment_actions)
        }

        # TODO: Change this into using a specific method to remove a network id?

        if tunnel_actions.size > 1
          flows << flow_create(table: TABLE_FLOOD_TUNNELS,
            goto_table: TABLE_FLOOD_SEGMENT,
            priority: 1,
            match_network: property_id,
            actions: tunnel_actions,
            cookie: property_id | COOKIE_TYPE_NETWORK)
        else
          @dp_info.del_flows(table_id: TABLE_FLOOD_TUNNELS,
            cookie: property_id | COOKIE_TYPE_NETWORK,
            cookie_mask: COOKIE_MASK)
        end

        if !segment_actions.empty?
          flows << flow_create(table: TABLE_FLOOD_SEGMENT,
            priority: 1,
            match_network: property_id,
            actions: segment_actions,
            cookie: property_id | COOKIE_TYPE_NETWORK)
        else
          @dp_info.del_flows(table_id: TABLE_FLOOD_SEGMENT,
            cookie: property_id | COOKIE_TYPE_NETWORK,
            cookie_mask: COOKIE_MASK)
        end

      when :update_segments
        tunnel_actions = [:tunnel_id => property_id | TUNNEL_FLAG_MASK]
        segment_actions = []

        @items.each { |item_id, item|
          item.actions_append_flood_segment(property_id, tunnel_actions, segment_actions)
        }

        # TODO: Change this into using a specific method to remove a segment id?

        if tunnel_actions.size > 1
          flows << flow_create(table: TABLE_FLOOD_TUNNELS,
            goto_table: TABLE_FLOOD_SEGMENT,
            priority: 1,
            match_segment: property_id,
            actions: tunnel_actions,
            cookie: property_id | COOKIE_TYPE_SEGMENT)
        else
          @dp_info.del_flows(table_id: TABLE_FLOOD_TUNNELS,
            cookie: property_id | COOKIE_TYPE_SEGMENT,
            cookie_mask: COOKIE_MASK)
        end

        if !segment_actions.empty?
          flows << flow_create(table: TABLE_FLOOD_SEGMENT,
            priority: 1,
            match_segment: property_id,
            actions: segment_actions,
            cookie: property_id | COOKIE_TYPE_SEGMENT)
        else
          @dp_info.del_flows(table_id: TABLE_FLOOD_SEGMENT,
            cookie: property_id | COOKIE_TYPE_SEGMENT,
            cookie_mask: COOKIE_MASK)
        end
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

      tunnel = MW::Tunnel.find_or_create(options.merge(mode: tunnel_mode))

      internal_retrieve(options)
    end

    # Load or create the tunnel item if we have both host and remote
    # datapath networks.
    #
    #
    def activate_link(obj_type, host_dp_obj, remote_dp_obj, dp_obj_id)
      options = {
        src_datapath_id: @datapath_info.id,
        dst_datapath_id: remote_dp_obj[:datapath_id],
        src_interface_id: host_dp_obj[:interface_id],
        dst_interface_id: remote_dp_obj[:interface_id],
      }

      info log_format("activated #{obj_type} link",
                      "#{obj_type}:#{remote_dp_obj[obj_type]} " +
                      "remote_dp_obj:#{remote_dp_obj[:id]} " +
                      "datapath_id:#{remote_dp_obj[:datapath_id]} " +
                      "interface_id:#{remote_dp_obj[:interface_id]}")

      item = internal_retrieve(options)
      tunnel_mode = select_tunnel_mode(host_dp_obj[:interface_id], remote_dp_obj[:interface_id])

      if tunnel_mode == nil
        info log_format("cannot determine tunnel mode")
        # @dp_info.interface_manager.async.retrieve(id: remote_dp_obj[:interface_id])

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
      case obj_type
      when :network_id
        item.add_datapath_network(remote_dp_obj)
        add_property_id_to_update_queue(:update_networks, dp_obj_id)
      when :segment_id
        item.add_datapath_segment(remote_dp_obj)
        add_property_id_to_update_queue(:update_segments, dp_obj_id)
      when :route_link_id
        item.add_datapath_route_link(remote_dp_obj)
        add_property_id_to_update_queue(:update_route_links, dp_obj_id)
      end
    end

    def deactivate_link(obj_type, host_dp_obj, remote_dp_obj, dp_obj_id)
      options = {
        src_datapath_id: @datapath_info.id,
        dst_datapath_id: remote_dp_obj[:datapath_id],
        src_interface_id: host_dp_obj[:interface_id],
        dst_interface_id: remote_dp_obj[:interface_id],
      }

      item = internal_detect(options) || return

      info log_format("deactivated #{obj_type} link",
                      "#{obj_type}:#{remote_dp_obj[obj_type]} " +
                      "remote_dp_obj:#{remote_dp_obj[:id]} " +
                      "datapath_id:#{remote_dp_obj[:datapath_id]} " +
                      "interface_id:#{remote_dp_obj[:interface_id]}")

      case obj_type
      when :network_id
        item.remove_datapath_network(remote_dp_obj[:id])
        add_property_id_to_update_queue(:update_networks, dp_obj_id)
      when :segment_id
        item.remove_datapath_segment(remote_dp_obj[:id])
        add_property_id_to_update_queue(:update_segments, dp_obj_id)
      when :route_link_id
        item.remove_datapath_route_link(remote_dp_obj[:id])
        add_property_id_to_update_queue(:update_route_links, dp_obj_id)
      end

      # TODO: Add event to check if item should be unloaded. Currently
      # done here:
      item.unused? && publish(REMOVED_TUNNEL, id: item.id)
    end

    def set_tunnel_port_number(params)
      port_name = params[:port_name] || return
      port_number = params[:port_number] || return

      item = internal_retrieve(uuid: port_name)

      if item.nil?
        info log_format("could not find tunnel item for port name '#{port_name}'")

        # Either delete the tunnel or do something else.
        return
      end

      # TODO: Turn into an event, and use the same update_networks
      # list for all callers, with an event that pulls network id's to
      # update from the list.

      updated_networks = {}
      updated_segments = {}
      item.set_tunnel_port_number(port_number, updated_networks, updated_segments)

      add_property_ids_to_update_queue(:update_networks, updated_networks.keys)
      add_property_ids_to_update_queue(:update_segments, updated_segments.keys)
    end

    def clear_tunnel_port_number(params)
      port_name = params[:port_name] || return
      item = internal_retrieve(uuid: port_name) || return

      # TODO: Turn into an event, and use the same update_networks
      # list for all callers, with an event that pulls network id's to
      # update from the list.

      updated_networks = {}
      updated_segments = {}
      item.set_tunnel_port_number(port_number, updated_networks, updated_segments)

      add_property_ids_to_update_queue(:update_networks, updated_networks.keys)
      add_property_ids_to_update_queue(:update_segments, updated_segments.keys)

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
      # when :added_ipv4_address
      #   interface_added_ipv4_address(interface_id, params)
      # when :removed_ipv4_address
      #   interface = @interfaces.delete(interface_id)

      #   return if interface.nil?

        # Do stuff/event...

      when :set_host_port_number
        interface_set_host_port_number(interface_id, params)
      else
        error log_format("unknown updated_interface event '#{interface_event}'")
      end
    end

    # Temporary method while refactoring active interfaces.
    def interface_load_ip_lease(type, interface_id, ip_lease_id)
      return if interface_id.nil? || ip_lease_id.nil?

      ip_lease = MW::IpLease.batch[id: ip_lease_id].commit

      return if ip_lease.nil?
      return if @interfaces[interface_id] && @interfaces[interface_id][:network_id]

      interface_added_ipv4_address(interface_id,
                                   interface_mode: type,
                                   interface_id: interface_id,
                                   network_id: ip_lease.network_id,
                                   ipv4_address: IPAddr.new(ip_lease.ipv4_address, Socket::AF_INET))
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
      updated_segments = {}

      # A port number has already been set, handle this properly:
      if interface[:port_number]
      end

      interface[:port_number] = port_number

      items_with_src_interface(interface_id).each { |id, item|
        # Register this as an event instead, and use the values in
        # '@interfaces' when handling the event.
        item.set_host_port_number(port_number, updated_networks, updated_segments)
      }

      add_property_ids_to_update_queue(:update_networks, updated_networks.keys)
      add_property_ids_to_update_queue(:update_segments, updated_segments.keys)
    end

    #
    # Datapath network events:
    #

    # ADDED_HOST_DATAPATH_NETWORK on queue ':datapath_network'
    def added_host_datapath_network(params)
      host_dpn = create_dp_obj(:host_network, params) || return
      network_id = host_dpn[:network_id] || return

      interface_load_ip_lease(:host, host_dpn[:interface_id], host_dpn[:ip_lease_id])

      # Reorder so that we activate in the order of loading
      # internally, database and then create.
      remote_dpns = @remote_datapath_networks.select { |id, remote_dpn|
        remote_dpn[:network_id] == network_id
      }
      remote_dpns.each { |id, remote_dpn|
        activate_link(:network_id, host_dpn, remote_dpn, network_id)
      }
    end

    # ADDED_REMOTE_DATAPATH_NETWORK on queue ':datapath_network'
    def added_remote_datapath_network(params)
      remote_dpn = create_dp_obj(:remote_network, params) || return
      network_id = remote_dpn[:network_id] || return

      interface_load_ip_lease(:remote, remote_dpn[:interface_id], remote_dpn[:ip_lease_id])

      host_dpn = @host_networks[network_id]

      activate_link(:network_id, host_dpn, remote_dpn, network_id) if host_dpn
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
        deactivate_link(:network_id, host_dpn, remote_dpn, network_id)
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

      deactivate_link(:network_id, host_dpn, remote_dpn, network_id) if host_dpn
    end

    #
    # Datapath segment events:
    #

    # ADDED_HOST_DATAPATH_SEGMENT on queue ':datapath_segment'
    def added_host_datapath_segment(params)
      host_dpseg = create_dp_obj(:host_segment, params) || return
      segment_id = host_dpseg[:segment_id] || return

      interface_load_ip_lease(:host, host_dpseg[:interface_id], host_dpseg[:ip_lease_id])

      # Reorder so that we activate in the order of loading
      # internally, database and then create.
      remote_dpsegs = @remote_datapath_segments.select { |id, remote_dpseg|
        remote_dpseg[:segment_id] == segment_id
      }
      remote_dpsegs.each { |id, remote_dpseg|
        activate_link(:segment_id, host_dpseg, remote_dpseg, segment_id)
      }
    end

    # ADDED_REMOTE_DATAPATH_SEGMENT on queue ':datapath_segment'
    def added_remote_datapath_segment(params)
      remote_dpseg = create_dp_obj(:remote_segment, params) || return
      segment_id = remote_dpseg[:segment_id] || return

      interface_load_ip_lease(:remote, remote_dpseg[:interface_id], remote_dpseg[:ip_lease_id])

      host_dpseg = @host_segments[segment_id]

      activate_link(:segment_id, host_dpseg, remote_dpseg, segment_id) if host_dpseg
    end

    # REMOVED_HOST_DATAPATH_SEGMENT on queue ':datapath_segment'
    def removed_host_datapath_segment(params)
      dpseg_obj = params[:dp_obj] || return
      segment_id = dpseg_obj[:segment_id] || return

      host_dpseg = @host_segments.delete(segment_id) || return

      debug log_format("host datapath segment #{host_dpseg[:id]} removed for datapath #{host_dpseg[:datapath_id]}")

      # Reorder so that we activate in the order of loading
      # internally, database and then create.
      remote_dpsegs = @remote_datapath_segments.select { |id, remote_dpseg|
        remote_dpseg[:segment_id] == segment_id
      }
      remote_dpsegs.each { |id, remote_dpseg|
        deactivate_link(:segment_id, host_dpseg, remote_dpseg, segment_id)
      }
    end

    # REMOVED_REMOTE_DATAPATH_SEGMENT on queue ':datapath_segment'
    def removed_remote_datapath_segment(params)
      dpseg_obj = params[:dp_obj] || return
      dpseg_id = dpseg_obj[:id] || return
      segment_id = dpseg_obj[:segment_id] || return

      host_dpseg = @host_segments[segment_id]
      remote_dpseg = @remote_datapath_segments.delete(dpseg_id) || return

      debug log_format("remote datapath segment #{dpseg_id} removed for datapath #{remote_dpseg[:datapath_id]}")

      deactivate_link(:segment_id, host_dpseg, remote_dpseg, segment_id) if host_dpseg
    end

    #
    # Datapath route_link events:
    #

    # ADDED_HOST_DATAPATH_ROUTE_LINK on queue ':datapath_route_link'
    def added_host_datapath_route_link(params)
      host_dprl = create_dp_obj(:host_route_link, params) || return
      route_link_id = host_dprl[:route_link_id] || return

      interface_load_ip_lease(:host, host_dprl[:interface_id], host_dprl[:ip_lease_id])

      # Reorder so that we activate in the order of loading
      # internally, database and then create.
      remote_dprls = @remote_datapath_route_links.select { |id, remote_dprl|
        remote_dprl[:route_link_id] == route_link_id
      }
      remote_dprls.each { |id, remote_dprl|
        activate_link(:route_link_id, host_dprl, remote_dprl, route_link_id)
      }
    end

    # ADDED_REMOTE_DATAPATH_ROUTE_LINK on queue ':datapath_route_link'
    def added_remote_datapath_route_link(params)
      remote_dprl = create_dp_obj(:remote_route_link, params) || return
      route_link_id = remote_dprl[:route_link_id] || return

      interface_load_ip_lease(:remote, remote_dprl[:interface_id], remote_dprl[:ip_lease_id])

      host_dprl = @host_route_links[route_link_id]

      activate_link(:route_link_id, host_dprl, remote_dprl, route_link_id) if host_dprl
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
      when :host_segment
        dst_list, dst_log_prefix = @host_segments, "host datapath segment"
        dst_key_type = dst_object_type = :segment_id
      when :remote_segment
        dst_list, dst_log_prefix = @remote_datapath_segments, "remote datapath segment"
        dst_key_type, dst_object_type = :id, :segment_id
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
      ip_lease_id = param_obj[:ip_lease_id]
      mac_address = param_obj[:mac_address] || return

      if dst_list[key_id]
        error log_format("#{dst_log_prefix} #{key_id} already added")
        return
      end

      debug log_format("#{dst_log_prefix} #{key_id} added for datapath #{datapath_id}",
                       "#{dst_object_type}:#{object_id} interface_id:#{interface_id} mac_address:#{mac_address} ip_lease_id:#{ip_lease_id}")

      dst_list[key_id] = {
        :id => id,
        :datapath_id => datapath_id,
        dst_object_type => object_id,
        :interface_id => interface_id,
        :ip_lease_id => ip_lease_id,
        :mac_address => mac_address
      }
    end

    # TODO: Make generic.
    def add_dpn_hash_to_updated_networks(dp_gens)
      dp_gens.map { |id, remote_dp_gens|
        remote_dp_gens[:network_id]
      }.tap { |network_ids|
        add_property_ids_to_update_queue(:update_networks, network_ids)
      }
    end

    def add_dpseg_hash_to_updated_segments(dp_gens)
      dp_gens.map { |id, remote_dp_gens|
        remote_dp_gens[:segment_id]
      }.tap { |segment_ids|
        add_property_ids_to_update_queue(:update_segments, segment_ids)
      }
    end

    def add_dprl_hash_to_updated_route_links(dp_gens)
      dp_gens.map { |id, remote_dp_gens|
        remote_dp_gens[:route_link_id]
      }.tap { |route_link_ids|
        add_property_ids_to_update_queue(:update_route_links, route_link_ids)
      }
    end

  end

end
