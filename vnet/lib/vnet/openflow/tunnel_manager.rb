# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TunnelManager < Manager

    #
    # Events:
    #
    subscribe_event REMOVED_TUNNEL, :unload
    subscribe_event INITIALIZED_TUNNEL, :install_item

    def initialize(*args)
      super
      @host_datapath_networks = {}
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
      end

      nil
    end

    def insert(dpn_id)
      datapath_network = create_datapath_network(dpn_id)
      return unless datapath_network

      options = {
        src_datapath_id: @datapath_info.id,
        dst_datapath_id: datapath_network[:datapath_id],
        src_interface_id: @host_datapath_networks[datapath_network[:network_id]][:interface_id],
        dst_interface_id: datapath_network[:interface_id],
      }

      item = item_by_params(options)

      unless item
        info log_format("creating tunnel entry",
                        options.map { |k, v| "#{k}: #{v}" }.join(" "))

        tunnel = MW::Tunnel.create(options)
        item = item_by_params(options)

        if item.nil? || !item.instance_of?(Tunnels::Base)
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
        item.datapath_networks.any? { |dpn| dpn[:id] == dpn_id }
      }.tap do |item|
        return unless item

        datapath_network = item.remove_datapath_network(dpn_id)
        update_network_id(datapath_network[:network_id]) if datapath_network
        publish(REMOVED_TUNNEL, id: item.id) if item.unused?
      end
    end

    def prepare_network(dpn_id)
      datapath_network = create_datapath_network(dpn_id)
      return unless datapath_network
      @host_datapath_networks[datapath_network[:network_id]] = datapath_network
    end

    def remove_network(network_id)
      @host_datapath_networks.delete(network_id)
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

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} tunnel_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      return false if params[:display_name] && params[:display_name] != item.display_name
      return false if params[:port_name] && params[:port_name] != item.display_name
      return false if params[:dst_id] && params[:dst_id] != item.dst_id
      return false if params[:dst_datapath_id] && params[:dst_datapath_id] != item.dst_id
      return false if params[:dst_dpid] && params[:dst_dpid] != item.dst_dpid
      return false if params[:src_interface_id] && params[:src_interface_id] != item.src_interface_id
      return false if params[:dst_interface_id] && params[:dst_interface_id] != item.dst_interface_id
      true
    end

    def select_filter_from_params(params)
      return nil if @datapath_info.nil?

      return params if params.keys == [:src_datapath_id, :dst_datapath_id, :src_interface_id, :dst_interface_id]

      # Ensure to update tunnel items only belonging to this
      { src_datapath_id: @datapath_info.id }.tap do |options|
        case
        when params[:id]              then options[:id] = params[:id]
        when params[:uuid]            then options[:uuid] = params[:uuid]
        when params[:display_name]    then options[:display_name] = params[:display_name]
        when params[:port_name]       then options[:display_name] = params[:port_name]
        when params[:dst_id]          then options[:dst_datapath_id] = params[:dst_id]

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
      Tunnels::Base.new(
        dp_info: @dp_info,
        manager: self,
        map: item_map
      )
    end

    def initialized_item_event
      INITIALIZED_TUNNEL
    end

    def select_item(filter)
      # Using fill for ip_leases/ip_addresses isn't going to give us a
      # proper event barrier.
      MW::Tunnel.batch[filter].commit(
        fill: [
          :dst_datapath,
          { :dst_interface => :ipv4_address },
          { :src_interface => :ipv4_address },
        ]
      )
    end
    
    def install_item(params)
      item = @items[params[:item_map].id]
      return unless item

      debug log_format("install #{item.uuid}/#{item.id}")

      item.install
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
      dpn_map = MW::DatapathNetwork.batch[dpn_id].commit(fill: :datapath)
      return unless  dpn_map

      {
        id: dpn_map.id,
        dpid: dpn_map.datapath.dpid,
        ipv4_address: dpn_map.datapath.ipv4_address,
        datapath_id: dpn_map.datapath_id,
        network_id: dpn_map.network_id,
        interface_id: dpn_map.interface_id,
        broadcast_mac_address: Trema::Mac.new(dpn_map.broadcast_mac_address),
      }
    end

  end

end
