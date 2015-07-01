# -*- coding: utf-8 -*-

module Vnet::Core

  class DatapathManager < Vnet::Core::Manager
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
      when :host
        proc { |id, item| item.mode == :host }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {dpid: params[:dpid]} if params.has_key? :dpid
      filter << {host: @dp_info.dpid} if params.has_key? :host # TODO: Not sufficient.
      filter
    end

    def item_initialize(item_map)
      if item_map.dpid == @dp_info.dpid
        item_class = Datapaths::Host
      else
        item_class = Datapaths::Remote
      end

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_post_install(item, item_map)
      item_map.batch.datapath_networks.commit.each { |dpn_map|
        internal_added_datapath_network(item, dpn_map)
      }

      item_map.batch.datapath_route_links.commit.each { |dprl_map|
        internal_added_datapath_route_link(item, dprl_map)
      }
    end

    # TODO: Currently we initialize all datapaths, however in the
    # future this should be done only when needed. Bootstrap handles
    # loading the host datapath, so it can be ignored also. 
    def created_item(params)
      return if internal_detect_by_id(params)
      internal_new_item(mw_class.new(params))
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
      network_id = params[:network_id] || return
      network = @active_networks.delete(network_id) || return

      @items.select { |id, item|
        item.has_active_network?(network_id)
      }.each { |id, item|
        publish(DEACTIVATE_DATAPATH_NETWORK, id: item.id, network_id: network_id)
      }

      # unload_datapath_networks(network_id)
    end

    # ADDED_DATAPATH_NETWORK on queue 'item.id'
    def added_datapath_network(params)
      item = internal_detect_by_id(params)

      if item.nil?
        # TODO: Make sure we don't lock here...
        return internal_retrieve(id: params[:id])
      end

      # TODO: Fix this so all params contain the needed information.
      case 
      when params[:dpn_map]
        dpn_map = params[:dpn_map]
      when params[:network_id]
        dpn_map = MW::DatapathNetwork.batch[datapath_id: item.id, network_id: params[:network_id]].commit
      end

      internal_added_datapath_network(item, dpn_map)
    end

    # REMOVED_DATAPATH_NETWORK on queue 'item.id'
    def removed_datapath_network(params)
      item = internal_detect_by_id(params) || return
      network_id = params[:network_id] || return

      item.deactivate_network_id(network_id)
      item.remove_active_network(network_id)

      if !item.host? && item.unused?
        publish(REMOVED_DATAPATH, id: item.id)
      end
    end

    # ACTIVATE_DATAPATH_NETWORK on queue 'item.id'
    def activate_datapath_network(params)
      item = internal_detect_by_id(params) || return

      network_id = params[:network_id] || return
      network = @active_networks[network_id]

      info log_format("activating datapath network #{network_id}")

      item.activate_network_id(network_id) if network
    end

    # DEACTIVATE_DATAPATH_NETWORK on queue 'item.id'
    def deactivate_datapath_network(params)
      item = internal_detect_by_id(params) || return

      network_id = params[:network_id] || return
      network = @active_networks[network_id]

      info log_format("deactivating datapath network #{network_id}")

      item.deactivate_network_id(network_id)

      if !item.host? && item.unused?
        publish(REMOVED_DATAPATH, id: item.id)
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

        self.async.internal_retrieve(id: dpn_map.datapath_id)
      }
    end

    #
    # Route link events:
    #

    # ACTIVATE_ROUTE_LINK_ON_HOST on queue ':route_link'
    def activate_route_link(params)
      route_link_id = params[:route_link_id] || return
      return if @active_route_links.has_key? route_link_id

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

      @items.select { |id, item|
        item.has_active_route_link?(route_link_id)
      }.each { |id, item|
        publish(DEACTIVATE_DATAPATH_ROUTE_LINK, id: item.id, route_link_id: route_link_id)
      }

      # unload_datapath_route_links(route_link_id)
    end

    # ADDED_DATAPATH_ROUTE_LINK on queue 'item.id'
    def added_datapath_route_link(params)
      item = internal_detect_by_id(params)

      if item.nil?
        # TODO: Make sure we don't loop here...
        return internal_retrieve(id: params[:id])
      end

      # TODO: Fix this so all params contain the needed information.
      case 
      when params[:dprl_map]
        dprl_map = params[:dprl_map]
      when params[:route_link_id]
        dprl_map = MW::DatapathRouteLink.batch[datapath_id: item.id, route_link_id: params[:route_link_id]].commit
      end

      internal_added_datapath_route_link(item, dprl_map)
    end

    # REMOVED_DATAPATH_ROUTE_LINK on queue 'item.id'
    def removed_datapath_route_link(params)
      item = internal_detect_by_id(params) || return
      route_link_id = params[:route_link_id] || return

      item.remove_active_route_link(route_link_id)
      item.deactivate_route_link_id(route_link_id)

      if !item.host? && item.unused?
        publish(REMOVED_DATAPATH, id: item.id)
      end
    end

    # ACTIVATE_DATAPATH_ROUTE_LINK on queue 'item.id'
    def activate_datapath_route_link(params)
      item = internal_detect_by_id(params) || return
      route_link_id = params[:route_link_id] || return
      route_link = @active_route_links[route_link_id]

      item.activate_route_link_id(route_link_id) if route_link
    end

    # DEACTIVATE_DATAPATH_ROUTE_LINK on queue 'item.id'
    def deactivate_datapath_route_link(params)
      item = internal_detect_by_id(params) || return
      route_link_id = params[:route_link_id] || return
      route_link = @active_route_links[route_link_id]

      item.deactivate_route_link_id(route_link_id)

      if !item.host? && item.unused?
        publish(REMOVED_DATAPATH, id: item.id)
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

        self.async.internal_retrieve(id: dprl_map.datapath_id)
      }
    end

    #
    # Refactored:
    #

    def internal_added_datapath_network(item, dpn_map)
      network_id = (dpn_map && dpn_map.network_id) || return

      item.add_active_network(dpn_map)
      item.activate_network_id(network_id) if @active_networks[network_id]
    end

    def internal_added_datapath_route_link(item, dprl_map)
      route_link_id = (dprl_map && dprl_map.route_link_id) || return

      item.add_active_route_link(dprl_map)
      item.activate_route_link_id(route_link_id) if @active_route_links[route_link_id]
    end

  end

end
