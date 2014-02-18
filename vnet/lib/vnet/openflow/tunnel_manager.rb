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

    def initialize(*args)
      super
      @host_networks = {}
      @remote_datapath_networks = {}
      @interfaces = {}
    end

    def update_item(params)
      item = internal_detect(params)
      return nil if item.nil?

      case params[:event]
      when :set_port_number
        update_tunnel(item, params[:port_number]) if params[:port_number]
      when :clear_port_number
        update_tunnel(item, nil)
      end

      item_to_hash(item)
    end

    def update(params)
      case params[:event]
      when :update_network
        update_network_id(params[:network_id]) if params[:network_id]
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
      end

      nil
    end

    #
    # Refactor:
    #

    def insert_foo(datapath_network)
      if @host_networks[datapath_network[:network_id]].nil?
        error "XXXXXXXXXXXXXXXXXXXXXXX #{datapath_network.inspect}"
        return
      end

      options = {
        src_datapath_id: @datapath_info.id,
        dst_datapath_id: datapath_network[:datapath_id],
        src_interface_id: @host_networks[datapath_network[:network_id]][:interface_id],
        dst_interface_id: datapath_network[:interface_id],
      }

      item = item_by_params(options)

      # Check tunnel mode here...

      unless item
        info log_format("creating tunnel entry",
                        options.map { |k, v| "#{k}: #{v}" }.join(" "))

        tunnel = MW::Tunnel.create(options.merge(mode: :gre))
        item = item_by_params(options)

        if item.nil?
          warn log_format('could not create tunnel',
                          options.map { |k, v| "#{k}: #{v}" }.join(" "))
          return
        end
      end

      item.add_datapath_network(datapath_network)
      update_network_id(datapath_network[:network_id])

      info log_format(
        "insert datapath network",
        "datapath_id:#{datapath_network[:datapath_id]} " +
        "network_id:#{datapath_network[:network_id]} " +
        "interface_id:#{datapath_network[:interface_id]}"
      )
    end

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

    # TODO: Add a way to enable/disable networks:
    def prepare_network(dpn_id)
      # datapath_network = create_datapath_network(dpn_id)
      # return unless datapath_network
      # @host_datapath_networks[datapath_network[:network_id]] = datapath_network
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

    #
    # Create / Delete tunnels:
    #

    def item_initialize(item_map, params)
      params = { dp_info: @dp_info,
                 manager: self,
                 map: item_map }

      case item_map.mode
      when 'gre'     then Tunnels::Gre.new(params)
      when 'mac2mac' then Tunnels::Mac2Mac.new(params)
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
      item = @items[params[:item_map].id]
      return unless item

      debug log_format("install #{item.uuid}/#{item.id}",
                       "src_interface_id:#{item.src_interface_id} dst_interface_id:#{item.dst_interface_id}")

      item.install

      dst_interface = @interfaces[item.dst_interface_id]
      src_interface = @interfaces[item.src_interface_id]
      item.set_dst_ipv4_address(dst_interface[:network_id], dst_interface[:ipv4_address]) if dst_interface
      item.set_src_ipv4_address(src_interface[:network_id], src_interface[:ipv4_address]) if src_interface

      # Should be an event that is exclusive for dpn updates (?):
      remote_dpns = @remote_datapath_networks.select { |id, remote_dpn|
        remote_dpn[:datapath_id] == item.dst_datapath_id && remote_dpn[:interface_id] == item.dst_interface_id
      }
      remote_dpns.each { |id, remote_dpn|
        item.add_datapath_network(remote_dpn)
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

      update_tunnel(item, nil)

      item.uninstall

      MW::Tunnel.batch.destroy(item.uuid).commit

      item
    end

    #
    # Event handlers:
    #

    def update_tunnel(item, port_number)
      return if item.port_number == port_number
      item.port_number = port_number

      item.datapath_networks.each { |dpn|
        update_network_id(dpn[:network_id])
      }
    end

    # Move this into GRE...
    def update_network_id(network_id)
      actions = [:tunnel_id => network_id | TUNNEL_FLAG_MASK]

      @items.select { |item_id, item|
        next false if item.port_number.nil?

        item.datapath_networks.any? { |dpn| dpn[:network_id] == network_id }

      }.each { |item_id, item|
        actions << {:output => item.port_number}
      }

      cookie = network_id | COOKIE_TYPE_NETWORK

      flows = []
      flows << flow_create(:default,
                           table: TABLE_FLOOD_TUNNELS,
                           priority: 1,
                           match_network: network_id,
                           actions: actions,
                           cookie: cookie)

      @dp_info.add_flows(flows)
    end

    def create_datapath_network(dpn_id)
      # TODO: Fix this...
      #
      # We should only use the dpn data we get from DatapathManager...

      dpn_map = MW::DatapathNetwork.batch[dpn_id].commit
      return unless dpn_map

      { id: dpn_map.id,
        datapath_id: dpn_map.datapath_id,
        interface_id: dpn_map.interface_id,
        network_id: dpn_map.network_id,
        broadcast_mac_address: Trema::Mac.new(dpn_map.broadcast_mac_address),
      }
    end

    #
    # Interface events:
    #

    def updated_interface(params)
      interface_event = params[:interface_event]
      return if interface_event.nil?

      case interface_event
      when :added_ipv4_address then interface_added_ipv4_address(params)
      when :removed_ipv4_address
        interface = @interfaces.delete(interface_id)

        return if interface.nil?
        
        # Do stuff/event...
      else
        error log_format("unknown updated_interface event '#{interface_event}'")
      end
    end

    def interface_added_ipv4_address(params)
      interface_id = params[:interface_id]
      interface_mode = params[:interface_mode]
      return if interface_id.nil?

      if interface_mode != :host && interface_mode != :remote
        error log_format("updated_interface received unknown interface_mode '#{interface_mode}'")
        return
      end

      debug log_format("#{interface_mode} interface #{interface_id} added ipv4 address",
                       "network_id:#{params[:network_id]} ipv4_address:#{params[:ipv4_address]}")

      # If already exists, clean up instead.
      interface = @interfaces[interface_id] ||= {
        :mode => interface_mode,
        :ipv4_address => nil,
      }

      # Check if interface mode matches...
      interface[:network_id] = params[:network_id]
      interface[:ipv4_address] = params[:ipv4_address]

      case interface_mode
      when :host
        @items.select { |id, item|
          item.src_interface_id == interface_id
        }.each { |id, item|
          # Register this as an event instead, and use the values in
          # '@interfaces' when handling the event.
          item.set_src_ipv4_address(interface[:network_id], interface[:ipv4_address])
        }
      when :remote
        @items.select { |id, item|
          item.dst_interface_id == interface_id
        }.each { |id, item|
          # Register this as an event instead, and use the values in
          # '@interfaces' when handling the event.
          item.set_dst_ipv4_address(interface[:network_id], interface[:ipv4_address])
        }
      end
    end

    #
    # Update datapath states:
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

      

      item = item_by_params(options)

      # Create separate method...
      #
      # Consider adding an event for doing create?
      if item.nil?
        info log_format("creating tunnel entry",
                        options.map { |k, v| "#{k}:#{v}" }.join(" "))

        tunnel = MW::Tunnel.create(options.merge(mode: :gre))
        item = item_by_params(options)

        if item.nil?
          warn log_format('could not create tunnel',
                          options.map { |k, v| "#{k}:#{v}" }.join(" "))
        end

        return
      end

      # Check tunnel mode here...

      # We make sure not to yield before the dpn has been added to
      # item.
      item.add_datapath_network(remote_dpn)

      # TODO: Consider making this an event?
      update_network_id(network_id)
    end

  end

end
