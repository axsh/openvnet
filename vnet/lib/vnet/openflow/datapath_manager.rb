# -*- coding: utf-8 -*-

module Vnet::Openflow

  class DatapathManager < Manager

    #
    # Events:
    #
    subscribe_event ADDED_DATAPATH, :create_item
    subscribe_event REMOVED_DATAPATH, :unload
    subscribe_event INITIALIZED_DATAPATH, :install_item

    # add activate_datapath_network_on_host?..
    subscribe_event ACTIVATE_NETWORK_ON_HOST, :activate_network
    subscribe_event DEACTIVATE_NETWORK_ON_HOST, :deactivate_network

    subscribe_event ADDED_DATAPATH_NETWORK, :added_datapath_network
    subscribe_event REMOVED_DATAPATH_NETWORK, :removed_datapath_network
    subscribe_event ACTIVATE_DATAPATH_NETWORK, :activate_datapath_network
    subscribe_event DEACTIVATE_DATAPATH_NETWORK, :deactivate_datapath_network

    def initialize(*args)
      super
      @active_networks = {}
    end

    def update(params)
      case params[:event]
      when :activate_network
        publish(ACTIVATE_NETWORK_ON_HOST,
                id: :network,
                network_id: params[:network_id])
      when :deactivate_network
        publish(DEACTIVATE_NETWORK_ON_HOST,
                id: :network,
                network_id: params[:network_id])
      when :activate_route_link
        activate_route_link(params)
      when :deactivate_route_link
        # deactivate_route_link(params)
      end

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
      true
    end

    def select_filter_from_params(params)
      {}.tap do |options|
        case
        when params[:id]    then options[:id] = params[:id]
        when params[:dpid]  then options[:dpid] = params[:dpid]
        end
      end
    end

    def select_item(filter)
      MW::Datapath.batch[filter].commit
    end

    def item_initialize(item_map, params)
      item_class =
        if item_map.dpid == @dp_info.dpid
          Datapaths::Host
        else
          Datapaths::Remote
        end

      item_class.new(
        dp_info: @dp_info,
        manager: self,
        map: item_map
      )
    end

    def initialized_item_event
      INITIALIZED_DATAPATH
    end

    def install_item(params)
      item_map =  params[:item_map]
      item = @items[item_map.id]
      return unless item

      item.install

      debug log_format("install #{item.uuid}/#{item.id}")

      item_map.batch.datapath_networks.commit.each do |dpn_map|
        publish(ADDED_DATAPATH_NETWORK, id: item.id, dpn_map: dpn_map)
      end

      item
    end

    def create_item(params)
      debug log_format("creating datapath id: #{params[:id]}")
      return if @items[params[:id]]

      if @dp_info.dpid != params[:dpid]
        item(id: params[:id])
        return
      end

      @dp_info.datapath.switch_ready
    end

    def delete_item(item)
      item = @items.delete(item.id)
      return unless item

      debug log_format("deleting datapath: #{item.uuid}/#{item.id}")

      item.uninstall

      # Remember to remove dpn's...

      item
    end

    #
    # Network events:
    #

    # ACTIVATE_NETWORK_ON_HOST on queue ':network'
    def activate_network(params)
      network_id = params[:network_id] || return
      return if @active_networks.has_key? network_id

      @active_networks[network_id] = {
      }

      @items.select { |id, item|
        item.has_active_network?(network_id)
      }.each { |id, item|
        publish(ACTIVATE_DATAPATH_NETWORK, id: item.id, network_id: network_id)
      }

      load_datapath_networks(network_id)
    end

    # DEACTIVATE_NETWORK_ON_HOST on queue ':network'
    def deactivate_network(params)
    end

    # ADDED_DATAPATH_NETWORK on queue 'item.id'
    def added_datapath_network(params)
      item_id = params[:id] || return
      item = @items[item_id]

      if item.nil?
        return item_by_params(id: item_id)
      end

      dpn_map = params[:dpn_map] || return
      network_id = dpn_map.network_id || return

      item.add_active_network(dpn_map)
      item.activate_network_id(network_id) if @active_networks[network_id]
    end

    # REMOVED_DATAPATH_NETWORK on queue 'item.id'
    def removed_datapath_network(params)
      item = @item[params[:id]] || return
      dpn_map = params[:dpn_map] || return

      item.remove_active_network(dpn_map.network_id)
      item.deactivate_network(network_id) unless @active_networks[network_id]

      if !item.host? && item.unused?
        publish(REMOVED_DATAPATH, id: dpn_map.datapath_id)
      end
    end

    # ACTIVATE_DATAPATH_NETWORK on queue 'item.id'
    def activate_datapath_network(params)
      item = @items[params[:id]] || return
      network_id = params[:network_id] || return
      network = @active_networks[network_id]

      item.activate_network_id(network_id) if network
    end

    # DEACTIVATE_DATAPATH_NETWORK on queue 'item.id'
    def deactivate_datapath_network(params)
      item = @items[params[:id]] || return
      network_id = params[:network_id] || return
      network = @active_networks[network_id]

      item.deactivate_network_id(network_id) unless network

      if !item.host? && item.unused?
        publish(REMOVED_DATAPATH, id: dpn_map.datapath_id)
      end
    end

    #
    # Networks:
    #

    # Require queue ':network'
    def load_datapath_networks(network_id)
      # Load all datapath networks on other datapaths.

      MW::DatapathNetwork.batch.where(network_id: network_id).all.commit.each { |dpn_map|
        next if dpn_map.datapath_id == @datapath_info.id
        next if @items[dpn_map.datapath_id]

        self.async.item_by_params(id: dpn_map.datapath_id)
      }
    end

    #
    # Refactor:
    #

    # TODO: Turn this into an event.
    def activate_route_link(params)
      return if params[:route_link_id].nil?

      dp_rl_items = MW::DatapathRouteLink.batch.dataset.where(route_link_id: params[:route_link_id]).all.commit(:fill => :route_link)

      dp_rl_items.each { |dp_rl|
        item = item_by_params(id: dp_rl.datapath_id)
        next if item.nil?

        item.add_active_route_link(dp_rl)
      }
    end

  end

end
