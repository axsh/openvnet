# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TunnelManager < Manager

    #
    # Events:
    #
    subscribe_event REMOVED_TUNNEL, :unload
    subscribe_event INITIALIZED_TUNNEL, :install_item

    def update_item(params)
      item = item_by_params(params)
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

    #
    # Refactor...
    #

    def create_all_tunnels
      debug log_format("creating tunnel ports")

      if @datapath_info.nil?
        error log_format('datapath information not loaded')
        return nil
      end

      MW::Datapath.batch[@datapath_info.id].on_other_segments.commit.each { |target_dp_map|
        item = item_by_params(dst_id: target_dp_map.id,
                              dst_dp_map: target_dp_map)
        next if item

        create_item(dst_id: target_dp_map.id)
      }
    end

    def create_item(params)
      item = internal_detect(dst_id: params[:dst_id])
      return if item

      tunnel_name = "t-#{params[:dst_id]}"
      tunnel_map = MW::Tunnel.create(src_datapath_id: @datapath_info.id,
                                     dst_datapath_id: params[:dst_id],
                                     display_name: tunnel_name)

      debug log_format("create #{tunnel_map.uuid}/#{tunnel_map.id}")

      item(id: tunnel_map.id)
    end


    def insert(dpn_id)
      dpn_map = MW::DatapathNetwork.batch[dpn_id].commit(fill: :datapath)
      return unless dpn_map

      info log_format("insert datapath network",
                      "network_id:#{dpn_map.network_id} id:#{dpn_map.id}")

      item = internal_detect(dst_id: dpn_map.datapath_id)

      datapath_network = {
        :id => dpn_map.id,
        :dpid => dpn_map.datapath.dpid,
        :ipv4_address => dpn_map.datapath.ipv4_address,
        :datapath_id => dpn_map.datapath.dpid,
        :broadcast_mac_address => Trema::Mac.new(dpn_map.broadcast_mac_address),
        :network_id => dpn_map.network_id,
      }

      item.datapath_networks << datapath_network if item

      update_network_id(datapath_network[:network_id])
    end

    def prepare_network(network_id)
    end

    def remove_network_id_for_dpid(network_id, remote_dpid)
      # if #{remote_dpid} is equal to #{@dp_info.dpid},
      # it can be regard as the network deletion happens on
      # the local datapath (not on the remote datapath)

      if remote_dpid == @dp_info.dpid
        debug log_format('delete tunnel on local datapath',
                         "local_dpid:#{@dp_info.dpid} remote_dpid:#{remote_dpid}")

        delete_items = @items.select { |id, item|
          # debug log_format("try to delete tunnel #{item.display_name}")
          remove_datapath_network(item, network_id)
        }
      else
        debug log_format('delete tunnel for remote datapath',
                         "local_dpid:#{@dp_info.dpid} remote_dpid:#{remote_dpid}")

        delete_items = @items.select { |id, item|
          if item.dst_dpid == "0x%016x" % remote_dpid
            # debug log_format('found a tunnel to delete', "display_name:#{item.display_name}")
            remove_datapath_network(item, network_id)
          else
            false
          end
        }
      end

      delete_items.each { |id, item| delete_item(item) }

      update_network_id(network_id)
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
      return false if params[:dst_dpid] && params[:dst_dpid] != item.dst_dpid
      true
    end

    def select_filter_from_params(params)
      return nil if @datapath_info.nil?

      # Ensure to update tunnel items only belonging to this
      { src_datapath_id: @datapath_info.id }.tap do |options|
        case
        when params[:id]           then options[:id] = params[:id]
        when params[:uuid]         then options[:uuid] = params[:uuid]
        when params[:display_name] then options[:display_name] = params[:display_name]
        when params[:port_name]    then options[:display_name] = params[:port_name]
        when params[:dst_id]       then options[:dst_datapath_id] = params[:dst_id]
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

    def item_initialize(item_map)
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
      MW::Tunnel.batch[filter].commit(fill: :dst_datapath)
    end

    def install_item(params)
      item = @items[params[:item_map].id]

      debug log_format("install #{item.uuid}/#{item.id}")

      item.install
    end

    def delete_item(item)
      debug log_format("delete #{item.uuid}/#{item.id}")

      update_tunnel(item, nil)

      item.uninstall

      MW::Tunnel.batch.destroy(id: item.id).commit

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

    #
    # Refactor:
    #

    # Delete the item if it returns true.
    def remove_datapath_network(item, network_id)
      item.datapath_networks.delete_if { |dpn| dpn[:network_id] == network_id }

      if item.datapath_networks.empty?
        debug log_format("datapath networks is empty for #{item.display_name}")

        # Currently dynamic creation and deletion does not work
        #MW::Tunnel.batch[display_name: item.display_name].destroy.commit
        true
      else
        debug log_format("datapath networs is not empty for #{item.display_name}")
        false
      end
    end

  end

end
