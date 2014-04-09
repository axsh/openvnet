# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager < Vnet::Manager

    def initialize(params)
      super

      @active_networks = {}
      @active_route_links = {}
    end

    #
    # Events:
    #
    subscribe_event ROUTE_INITIALIZED, :install_item
    subscribe_event ROUTE_CREATED_ITEM, :created_item
    subscribe_event ROUTE_DELETED_ITEM, :unload_item

    subscribe_event ROUTE_ACTIVATE_NETWORK, :activate_network
    subscribe_event ROUTE_DEACTIVATE_NETWORK, :deactivate_network

    subscribe_event ROUTE_ACTIVATE_ROUTE_LINK, :activate_route_link
    subscribe_event ROUTE_DEACTIVATE_ROUTE_LINK, :deactivate_route_link

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def initialized_item_event
      ROUTE_INITIALIZED
    end

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      return false if params[:network_id] && params[:network_id] != item.network_id
      return false if params[:not_network_id] && params[:not_network_id] == item.network_id
      return false if params[:egress] && params[:egress] != item.egress
      return false if params[:ingress] && params[:ingress] != item.ingress
      true
    end

    def select_filter_from_params(params)
      return if params.has_key?(:uuid) && params[:uuid].nil?

      filters = []
      filters << {id: params[:id]} if params.has_key? :id

      create_batch(MW::Route.batch, params[:uuid], filters)
    end

    def item_initialize(item_map, params)
      item = Routes::Base.new(dp_info: @dp_info, map: item_map)

      item.active_network = @active_networks.has_key? item.network_id
      item.active_route_link = @active_route_links.has_key? item.route_link_id

      # While querying the database the active state of either network
      # or route link changed, so discard the item.
      return if !item.active_network && !item.active_route_link

      item
    end

    #
    # Create / Delete events:
    #

    def install_item(params)
      item_map = params[:item_map] || return
      item = (item_map.id && @items[item_map.id]) || return

      case
      when !item.active_network && !item.active_route_link
        # The state changed since item_initialize so we skip install,
        # but don't delete it as the unload event should be in the
        # event queue.
        return
      when item.active_network && !item.active_route_link
        # TODO: Use event...
        @dp_info.router_manager.async.retrieve(id: item.route_link_id)
      end

      debug log_format("install #{item.uuid}/#{item.id}")

      item.try_install

      # TODO: Refactor...
      @dp_info.interface_manager.async.retrieve(id: item.interface_id)

      # TODO: Router egress is a property of the interface...(?)
      @dp_info.interface_manager.async.update_item(event: :enable_router_egress,
                                                   id: item.interface_id)
    end
    
    def created_item(params)
      return if @items[params[:id]]
      return unless @active_route_links[params[:route_link_id]]

      internal_new_item(MW::Route.new(params), {})
    end

    # unload item on queue 'item.id'
    def unload_item(params)
      item = @items.delete(params[:id]) || return
      item.try_uninstall

      debug log_format("unloaded item #{item.uuid}/#{item.id}")
    end

    #
    # Network events:
    #

    # We should only active networks on this datapath that have
    # non-simulated/remote interfaces.
    #
    # Note: Replace by active segment once implemented.

    # TRANSLATION_ACTIVATE_NETWORK on queue ':network'
    def activate_network(params)
      network_id = params[:network_id] || return
      return if @active_networks.has_key? network_id

      routes = []

      @items.each { |id, item|
        next unless item.network_id == network_id

        item.active_network = true
        routes << item.id
      }
      @active_networks[network_id] = routes

      item_maps = MW::Route.batch.where(network_id: network_id).all.commit
      item_maps.each { |item_map| internal_new_item(item_map, {}) }
    end

    # TRANSLATION_DEACTIVATE_NETWORK on queue ':network'
    def deactivate_network(params)
      # return if params[:network_id].nil?
      # routes = @active_networks.delete(params[:network_id]) || return

    end

    #
    # Route Link events:
    #

    # Activating route links causes associated routes to be loaded,
    # however these are marked as having inactive networks.

    # TRANSLATION_ACTIVATE_ROUTE_LINK on queue ':route_link'
    def activate_route_link(params)
      route_link_id = params[:route_link_id] || return
      return if @active_route_links.has_key? route_link_id

      routes = []

      @items.each { |id, item|
        next unless item.route_link_id == route_link_id

        item.active_route_link = true
        routes << item.id
      }
      @active_route_links[route_link_id] = routes

      item_maps = MW::Route.batch.where(route_link_id: route_link_id).all.commit
      item_maps.each { |item_map| internal_new_item(item_map, {}) }
    end

    # TRANSLATION_DEACTIVATE_ROUTE_LINK on queue ':route_link'
    def deactivate_route_link(params)
      # return if params[:route_link_id].nil?
      # routes = @active_route_links.delete(params[:route_link_id]) || return

    end

  end

end
