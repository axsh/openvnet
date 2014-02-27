# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TunnelManager < Manager

    #
    # Events:
    #
    subscribe_event REMOVED_TUNNEL, :unload
    subscribe_event INITIALIZED_TUNNEL, :install_item

    subscribe_event ADDED_HOST_DATAPATH_NETWORK, :added_host_datapath_network
    subscribe_event ADDED_REMOTE_DATAPATH_NETWORK, :added_remote_datapath_network
    subscribe_event ADDED_HOST_DATAPATH_ROUTE_LINK, :added_host_datapath_route_link
    subscribe_event ADDED_REMOTE_DATAPATH_ROUTE_LINK, :added_remote_datapath_route_link

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
      when :updated_interface
        updated_interface(params)
      when :added_host_datapath_network
        publish(ADDED_HOST_DATAPATH_NETWORK,
                id: :datapath_network,
                host_dpn: params[:dpn])
      when :added_remote_datapath_network
        publish(ADDED_REMOTE_DATAPATH_NETWORK,
                id: :datapath_network,
                remote_dpn: params[:dpn])
      when :added_host_datapath_route_link
        publish(ADDED_HOST_DATAPATH_ROUTE_LINK,
                id: :datapath_route_link,
                host_dprl: params[:dprl])
      when :added_remote_datapath_route_link
        publish(ADDED_REMOTE_DATAPATH_ROUTE_LINK,
                id: :datapath_route_link,
                remote_dprl: params[:dprl])
      end

      nil
    end

    #
    # Refactor:
    #

    def remove(dpn_id)
      @items.values.find { |item|
        item.datapath_networks.any? { |dpn| dpn[:dpn_id] == dpn_id }
      }.tap do |item|
        return unless item

        datapath_network = item.remove_datapath_network(dpn_id)
        update_network_id(datapath_network[:network_id]) if datapath_network
        publish(REMOVED_TUNNEL, id: item.id) if item.unused?
      end
    end

    def remove_network(network_id)
      # @host_datapath_networks.delete(network_id)
      # TODO
      # * remove the flow which is created by `update_network_id`
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
      params = { dp_info: @dp_info,
                 manager: self,
                 map: item_map }

      tunnel_mode = select_tunnel_mode(item_map.src_interface_id, item_map.dst_interface_id)

      case tunnel_mode
      when :gre     then Tunnels::Gre.new(params)
      when :mac2mac then Tunnels::Mac2Mac.new(params)
      when :unknown then Tunnels::Unknown.new(params)
      else
        nil
      end
    end

    def initialized_item_event
      INITIALIZED_TUNNEL
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

      # Make sure we have the remote host interface loaded.
      @dp_info.interface_manager.async.retrieve(id: item.dst_interface_id)

      # Update networks:
      updated_networks = remote_dpns.map { |id, remote_dpns|
        remote_dpns[:network_id]
      }
      updated_networks.uniq!
      updated_networks.each { |network_id|
        update_network_id(network_id)
      }
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
    # Event handlers:
    #

    def update_network_id(network_id)
      tunnel_actions = [:tunnel_id => network_id | TUNNEL_FLAG_MASK]
      mac2mac_actions = []

      @items.each { |item_id, item|
        item.actions_append_flood(network_id, tunnel_actions, mac2mac_actions)
      }

      mac2mac_actions << {:eth_dst => MAC_BROADCAST} unless mac2mac_actions.empty?

      flows = []
      flows << flow_create(:default,
                           table: TABLE_FLOOD_SEGMENT,
                           goto_table: TABLE_FLOOD_TUNNELS,
                           priority: 1,
                           match_network: network_id,
                           actions: mac2mac_actions,
                           cookie: network_id | COOKIE_TYPE_NETWORK)
      flows << flow_create(:default,
                           table: TABLE_FLOOD_TUNNELS,
                           priority: 1,
                           match_network: network_id,
                           actions: tunnel_actions,
                           cookie: network_id | COOKIE_TYPE_NETWORK)

      @dp_info.add_flows(flows)
    end

    #
    # Tunnel events:
    #

    def create_tunnel(options, tunnel_mode)
      # Create separate method...
      #
      # Consider adding an event for doing create?
      info log_format("creating tunnel entry",
                      options.map { |k, v| "#{k}:#{v}" }.join(" "))

      tunnel = MW::Tunnel.create(options.merge(mode: tunnel_mode))

      item_by_params(options)
    end

    # Load or create the tunnel item if we have both host and remote
    # datapath networks.
    def activate_tunnel(host_dpn, remote_dpn, network_id)
      options = {
        src_datapath_id: @datapath_info.id,
        dst_datapath_id: remote_dpn[:datapath_id],
        src_interface_id: host_dpn[:interface_id],
        dst_interface_id: remote_dpn[:interface_id],
      }

      # TODO: Update log output:
      info log_format(
        "activated remote datapath network",
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

      # TODO: Consider making this an event?
      update_network_id(network_id)
    end

    #
    # Interface events:
    #

    # TODO: Use the :interface event queue.

    def updated_interface(params)
      interface_id = params[:interface_id]
      interface_event = params[:interface_event]
      return if interface_id.nil? || interface_event.nil?

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
      interface = interface_prepare(interface_id, interface_mode)

      # Check if interface mode matches...
      return if interface.nil?

      interface[:network_id] = params[:network_id]
      interface[:ipv4_address] = params[:ipv4_address]

      case interface_mode
      when :host
        items_with_src_interface(interface_id).each { |id, item|
          # Register this as an event instead, and use the values in
          # '@interfaces' when handling the event.
          item.set_src_ipv4_address(interface[:network_id], interface[:ipv4_address])

          next reload_item(item) if select_tunnel_mode(item.src_interface_id, item.dst_interface_id)
        }
      when :remote
        items_with_dst_interface(interface_id).each { |id, item|
          # Register this as an event instead, and use the values in
          # '@interfaces' when handling the event.
          item.set_dst_ipv4_address(interface[:network_id], interface[:ipv4_address])

          next reload_item(item) if select_tunnel_mode(item.src_interface_id, item.dst_interface_id)
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

      # TODO: We need to gather all the network id's that need to have
      # new flood flows.
      updated_networks.each { |network_id, value|
        update_network_id(network_id)
      }
    end

    #
    # Datapath network events:
    #

    def added_host_datapath_network(params)
      param_dpn = params[:host_dpn]
      return if param_dpn.nil?

      dpn_id = param_dpn[:dpn_id]
      datapath_id = param_dpn[:datapath_id]
      network_id = param_dpn[:network_id]
      interface_id = param_dpn[:interface_id]
      broadcast_mac_address = param_dpn[:broadcast_mac_address]
      return if dpn_id.nil?
      return if datapath_id.nil?
      return if network_id.nil?
      return if interface_id.nil?
      return if broadcast_mac_address.nil?
      
      if @host_networks[network_id]
        error log_format("host datapath network #{dpn_id} already added",
                         "network_id:#{network_id} interface_id:#{interface_id} broadcast_mac_address:#{broadcast_mac_address}")
        return
      end

      host_dpn = @host_networks[network_id] = {
        :dpn_id => dpn_id,
        :datapath_id => datapath_id, # Not needed
        :network_id => network_id,
        :interface_id => interface_id,
        :broadcast_mac_address => broadcast_mac_address
      }

      debug log_format("host datapath network #{dpn_id} added for datapath #{datapath_id}",
                       "network_id:#{network_id} interface_id:#{interface_id} broadcast_mac_address:#{broadcast_mac_address}")

      # Reorder so that we activate in the order of loading
      # internally, database and then create.
      remote_dpns = @remote_datapath_networks.select { |id, remote_dpn|
        remote_dpn[:network_id] == network_id
      }
      remote_dpns.each { |id, remote_dpn|
        activate_tunnel(host_dpn, remote_dpn, network_id)
      }
    end

    def added_remote_datapath_network(params)
      param_dpn = params[:remote_dpn]
      return if param_dpn.nil?

      dpn_id = param_dpn[:dpn_id]
      datapath_id = param_dpn[:datapath_id]
      network_id = param_dpn[:network_id]
      interface_id = param_dpn[:interface_id]
      broadcast_mac_address = param_dpn[:broadcast_mac_address]
      
      if @remote_datapath_networks[dpn_id]
        error log_format("remote datapath network #{dpn_id} already added")
        return
      end

      remote_dpn = @remote_datapath_networks[dpn_id] = {
        :dpn_id => dpn_id,
        :datapath_id => datapath_id,
        :network_id => network_id,
        :interface_id => interface_id,
        :broadcast_mac_address => broadcast_mac_address
      }

      debug log_format("remote datapath network #{dpn_id} added for datapath #{datapath_id}",
                       "network_id:#{network_id} interface_id:#{interface_id} broadcast_mac_address:#{broadcast_mac_address}")

      host_dpn = @host_networks[network_id]

      activate_tunnel(host_dpn, remote_dpn, network_id) if host_dpn
    end

    #
    # Datapath route_link events:
    #

    def added_host_datapath_route_link(params)
      param_dpn = params[:host_dpn]
      return if param_dpn.nil?

      dpn_id = param_dpn[:dpn_id]
      datapath_id = param_dpn[:datapath_id]
      route_link_id = param_dpn[:route_link_id]
      interface_id = param_dpn[:interface_id]
      mac_address = param_dpn[:mac_address]
      return if dpn_id.nil?
      return if datapath_id.nil?
      return if route_link_id.nil?
      return if interface_id.nil?
      return if mac_address.nil?
      
      if @host_route_links[route_link_id]
        error log_format("host datapath route_link #{dpn_id} already added",
                         "route_link_id:#{route_link_id} interface_id:#{interface_id} mac_address:#{mac_address}")
        return
      end

      host_dpn = @host_route_links[route_link_id] = {
        :dpn_id => dpn_id,
        :datapath_id => datapath_id, # Not needed
        :route_link_id => route_link_id,
        :interface_id => interface_id,
        :mac_address => mac_address
      }

      debug log_format("host datapath route_link #{dpn_id} added for datapath #{datapath_id}",
                       "route_link_id:#{route_link_id} interface_id:#{interface_id} mac_address:#{mac_address}")

      # Reorder so that we activate in the order of loading
      # internally, database and then create.
      remote_dpns = @remote_datapath_route_links.select { |id, remote_dpn|
        remote_dpn[:route_link_id] == route_link_id
      }
      remote_dpns.each { |id, remote_dpn|
        activate_tunnel(host_dpn, remote_dpn, route_link_id)
      }
    end

    def added_remote_datapath_route_link(params)
      param_dpn = params[:remote_dpn]
      return if param_dpn.nil?

      dpn_id = param_dpn[:dpn_id]
      datapath_id = param_dpn[:datapath_id]
      route_link_id = param_dpn[:route_link_id]
      interface_id = param_dpn[:interface_id]
      mac_address = param_dpn[:mac_address]
      
      if @remote_datapath_route_links[dpn_id]
        error log_format("remote datapath route_link #{dpn_id} already added")
        return
      end

      remote_dpn = @remote_datapath_route_links[dpn_id] = {
        :dpn_id => dpn_id,
        :datapath_id => datapath_id,
        :route_link_id => route_link_id,
        :interface_id => interface_id,
        :mac_address => mac_address
      }

      debug log_format("remote datapath route_link #{dpn_id} added for datapath #{datapath_id}",
                       "route_link_id:#{route_link_id} interface_id:#{interface_id} mac_address:#{mac_address}")

      host_dpn = @host_route_links[route_link_id]

      activate_tunnel(host_dpn, remote_dpn, route_link_id) if host_dpn
    end

  end

end
