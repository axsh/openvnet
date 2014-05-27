# -*- coding: utf-8 -*-

module Vnet::Openflow

  class DatapathManager < Vnet::Openflow::Manager
    include Vnet::Openflow::FlowHelpers

    #
    # Events:
    #
    subscribe_event DATAPATH_INITIALIZED, :load_item
    subscribe_event DATAPATH_UNLOAD_ITEM, :unload_item
    subscribe_event DATAPATH_CREATED_ITEM, :created_item
    subscribe_event DATAPATH_DELETED_ITEM, :unload_item

    subscribe_event ACTIVATE_NETWORK_ON_HOST, :activate_network
    subscribe_event DEACTIVATE_NETWORK_ON_HOST, :deactivate_network

    subscribe_event ADDED_DATAPATH_NETWORK, :added_datapath_network
    subscribe_event REMOVED_DATAPATH_NETWORK, :removed_datapath_network
    subscribe_event ACTIVATE_DATAPATH_NETWORK, :activate_datapath_network
    subscribe_event DEACTIVATE_DATAPATH_NETWORK, :deactivate_datapath_network

    subscribe_event ACTIVATE_ROUTE_LINK_ON_HOST, :activate_route_link
    subscribe_event DEACTIVATE_ROUTE_LINK_ON_HOST, :deactivate_route_link

    subscribe_event ADDED_DATAPATH_ROUTE_LINK, :added_datapath_route_link
    subscribe_event REMOVED_DATAPATH_ROUTE_LINK, :removed_datapath_route_link
    subscribe_event ACTIVATE_DATAPATH_ROUTE_LINK, :activate_datapath_route_link
    subscribe_event DEACTIVATE_DATAPATH_ROUTE_LINK, :deactivate_datapath_route_link

    def initialize(*args)
      super
      @active_networks = {}
      @active_route_links = {}
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Datapath
    end

    def initialized_item_event
      DATAPATH_INITIALIZED
    end

    def item_unload_event
      DATAPATH_UNLOAD_ITEM
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid, :dpid
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {dpid: params[:dpid]} if params.has_key? :dpid
      filter
    end

    def item_initialize(item_map, params)
      item_class =
        if item_map.dpid == @dp_info.dpid
          Datapaths::Host
        else
          Datapaths::Remote
        end

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_post_install(item, item_map)
      item_map.batch.datapath_networks.commit.each do |dpn_map|
        publish(ADDED_DATAPATH_NETWORK, id: item.id, dpn_map: dpn_map)
      end

      item_map.batch.datapath_route_links.commit.each do |dprl_map|
        publish(ADDED_DATAPATH_ROUTE_LINK, id: item.id, dprl_map: dprl_map)
      end
    end

    # Remove dpn and dprl events.

    def created_item(params)
      return if @items[params[:id]]

      # TODO: Check if we need to create the item.
      if @dp_info.dpid != params[:dpid]
        retrieve(id: params[:id])
        return
      end

      # TODO: move to install_item...
      @dp_info.datapath.switch_ready
    end

    #
    # Network events:
    #

    # ACTIVATE_NETWORK_ON_HOST on queue ':network'
    def activate_network(params)
      network_id = params[:network_id] || return
      return if @active_networks.has_key? network_id

      info log_format("activating network #{network_id}")

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
      network_id = params[:network_id] || return
      network = @active_networks.delete(network_id) || return

      info log_format("deactivating network #{network_id}")

      @items.select { |id, item|
        item.has_active_network?(network_id)
      }.each { |id, item|
        publish(DEACTIVATE_DATAPATH_NETWORK, id: item.id, network_id: network_id)
      }

      # unload_datapath_networks(network_id)
    end

    # ADDED_DATAPATH_NETWORK on queue 'item.id'
    def added_datapath_network(params)
      item_id = params[:id] || return
      item = @items[item_id]

      if item.nil?
        # TODO: Make sure we don't look here...
        return item_by_params(id: item_id)
      end

      case 
      when params[:dpn_map]
        dpn_map = params[:dpn_map]
        network_id = dpn_map.network_id
      when params[:network_id]
        network_id = params[:network_id]
        dpn_map = MW::DatapathNetwork.batch[datapath_id: item_id, network_id: network_id].commit
      end

      (dpn_map && network_id) || return

      item.add_active_network(dpn_map)
      item.activate_network_id(network_id) if @active_networks[network_id]
    end

    # REMOVED_DATAPATH_NETWORK on queue 'item.id'
    def removed_datapath_network(params)
      item = @items[params[:id]] || return
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
    # Network methods:
    #

    # Require queue ':network'
    def load_datapath_networks(network_id)
      # Load all datapath networks on other datapaths.

      return unless @datapath_info

      MW::DatapathNetwork.batch.where(network_id: network_id).all.commit.each { |dpn_map|
        next if dpn_map.datapath_id == @datapath_info.id
        next if @items[dpn_map.datapath_id]

        self.async.item_by_params(id: dpn_map.datapath_id)
      }
    end

    #
    # Route link events:
    #

    # ACTIVATE_ROUTE_LINK_ON_HOST on queue ':route_link'
    def activate_route_link(params)
      route_link_id = params[:route_link_id] || return
      return if @active_route_links.has_key? route_link_id

      info log_format("activating route link #{route_link_id}")

      @active_route_links[route_link_id] = {
      }

      @items.select { |id, item|
        item.has_active_route_link?(route_link_id)
      }.each { |id, item|
        publish(ACTIVATE_DATAPATH_ROUTE_LINK, id: item.id, route_link_id: route_link_id)
      }

      load_datapath_route_links(route_link_id)
    end

    # DEACTIVATE_ROUTE_LINK_ON_HOST on queue ':route_link'
    def deactivate_route_link(params)
      route_link_id = params[:route_link_id] || return
      route_link = @active_route_links.delete(route_link_id) || return

      info log_format("deactivating route link #{route_link_id}")

      @items.select { |id, item|
        item.has_active_route_link?(route_link_id)
      }.each { |id, item|
        publish(DEACTIVATE_DATAPATH_ROUTE_LINK, id: item.id, route_link_id: route_link_id)
      }

      # unload_datapath_route_links(route_link_id)
    end

    # ADDED_DATAPATH_ROUTE_LINK on queue 'item.id'
    def added_datapath_route_link(params)
      item_id = params[:id] || return
      item = @items[item_id]

      if item.nil?
        # TODO: Make sure we don't loop here...
        return item_by_params(id: item_id)
      end

      case 
      when params[:dprl_map]
        dprl_map = params[:dprl_map]
        route_link_id = dprl_map.route_link_id
      when params[:route_link_id]
        route_link_id = params[:route_link_id]
        dprl_map = MW::DatapathRouteLink.batch[datapath_id: item_id, route_link_id: route_link_id].commit
      end

      (dprl_map && route_link_id) || return

      item.add_active_route_link(dprl_map)
      item.activate_route_link_id(route_link_id) if @active_route_links[route_link_id]
    end

    # REMOVED_DATAPATH_ROUTE_LINK on queue 'item.id'
    def removed_datapath_route_link(params)
      item = @items[params[:id]] || return
      dprl_map = params[:dprl_map] || return

      item.remove_active_route_link(dprl_map.route_link_id)
      item.deactivate_route_link(route_link_id) unless @active_route_links[route_link_id]

      if !item.host? && item.unused?
        publish(REMOVED_DATAPATH, id: dprl_map.datapath_id) # TODO FOOO...
      end
    end

    # ACTIVATE_DATAPATH_ROUTE_LINK on queue 'item.id'
    def activate_datapath_route_link(params)
      item = @items[params[:id]] || return
      route_link_id = params[:route_link_id] || return
      route_link = @active_route_links[route_link_id]

      item.activate_route_link_id(route_link_id) if route_link
    end

    # DEACTIVATE_DATAPATH_ROUTE_LINK on queue 'item.id'
    def deactivate_datapath_route_link(params)
      item = @items[params[:id]] || return
      route_link_id = params[:route_link_id] || return
      route_link = @active_route_links[route_link_id]

      item.deactivate_route_link_id(route_link_id) unless route_link

      if !item.host? && item.unused?
        publish(REMOVED_DATAPATH, id: dprl_map.datapath_id) # TODO FOOOO....
      end
    end

    #
    # Route links:
    #

    # Require queue ':route_link'
    def load_datapath_route_links(route_link_id)
      # Load all datapath route_links on other datapaths.

      return unless @datapath_info

      MW::DatapathRouteLink.batch.where(route_link_id: route_link_id).all.commit.each { |dprl_map|
        next if dprl_map.datapath_id == @datapath_info.id
        next if @items[dprl_map.datapath_id]

        self.async.item_by_params(id: dprl_map.datapath_id)
      }
    end

  end

end
