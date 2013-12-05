# -*- coding: utf-8 -*-

module Vnet::Openflow

  class DatapathManager < Manager

    #
    # Events:
    #
    subscribe_event ADDED_DATAPATH, :create_item
    subscribe_event REMOVED_DATAPATH, :unload
    subscribe_event INITIALIZED_DATAPATH, :install_item

    subscribe_event ADDED_DATAPATH_NETWORK, :add_datapath_network
    subscribe_event REMOVED_DATAPATH_NETWORK, :remove_datapath_network

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapath_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      true
    end
    
    def select_item(filter)
      # Using fill for ip_leases/ip_addresses isn't going to give us a
      # proper event barrier.
      MW::Datapath.batch[filter].commit(fill: :datapath_networks)
    end

    def item_initialize(item_map)
      Datapaths::Base.new(dp_info: @dp_info,
                          manager: self,
                          owner_dc_segment_id: @datapath_info.dc_segment_id,
                          map: item_map)
    end

    def initialized_item_event
      INITIALIZED_DATAPATH
    end

    def install_item(params)
      item_map = params[:item_map]
      item = @items[item_map.id]
      return unless item

      debug log_format("install #{item_map.uuid}/#{item_map.id}")

      item.install

      if item.owner?
        item_map.datapath_networks.each do |dpn_map|
          publish(ADDED_DATAPATH_NETWORK, dpn_map: dpn_map)
        end
      end

      item
    end

    def create_item(params)
      debug log_format("creating datapath id: #{params[:id]}")
      return if @items[params[:id]]

      if @datapath_info && @datapath_info.id != params[:id]
        item(id: params[:id])
        return
      end

      @dp_info.datapath.switch_ready
    end

    def delete_item(item)
      debug log_format("deleting datapath: #{item.uuid}/#{item.id}")

      item.uninstall
      item
    end

    def add_datapath_network(params)
      dpn_map = params[:dpn_map] || MW::DatapathNetwork.find(id: params[:datapath_network_id])
      return unless dpn_map

      activate_network(dpn_map)

      # need to be propagated if it is newly added network
      if dpn_map.datapath_id == @datapath_info.id
        dpn_map.batch.datapath_networks_in_the_same_network.commit.each do |peer_dpn_map|
          activate_network(peer_dpn_map)
        end
      end
    end

    def remove_datapath_network(params)
      dpn_map = MW::DatapathNetwork.batch.with_deleted.first(id: params[:datapath_network_id]).commit
      return unless dpn_map.deleted_at

      deactivate_network(dpn_map)
    end

    def activate_network(dpn_map)
      item = item_by_params(id: dpn_map.datapath_id)
      return if item.nil?

      item.add_active_network(dpn_map)
    end

    def deactivate_network(dpn_map)
      item = item_by_params(id: dpn_map.datapath_id)
      return if item.nil?

      if item.remove_active_network_id(dpn_map.network_id)
        if item.unused? && !item.owner?
          publish(REMOVED_DATAPATH, id: dpn_map.datapath_id)
        end
      end
    end
  end

end
