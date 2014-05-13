# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager < Vnet::Openflow::Manager
    include ActiveNetworks
    include ActiveRouteLinks

    #
    # Events:
    #

    subscribe_event ROUTE_INITIALIZED, :load_item
    subscribe_event ROUTE_UNLOAD_ITEM, :unload_item
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

    def mw_class
      MW::Route
    end

    def initialized_item_event
      ROUTE_INITIALIZED
    end

    def item_unload_event
      ROUTE_UNLOAD_ITEM
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

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {interface_id: params[:interface_id]} if params.has_key? :interface_id
      filter << {network_id: params[:network_id]} if params.has_key? :network_id
      filter << {route_link_id: params[:route_link_id]} if params.has_key? :route_link_id
      filter
    end

    def select_filter_from_params(params)
      return if params.has_key?(:uuid) && params[:uuid].nil?

      create_batch(mw_class.batch, params[:uuid], query_filter_from_params(params))
    end

    def item_initialize(item_map, params)
      item_class = Routes::Base

      item = item_class.new(dp_info: @dp_info, map: item_map)

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

    def item_pre_install(item, item_map)
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
    end

    def item_post_install(item, item_map)
      # TODO: Refactor...
      @dp_info.interface_manager.async.retrieve(id: item.interface_id)

      # TODO: Router egress is a property of the interface...(?)
      @dp_info.interface_manager.publish(Vnet::Event::INTERFACE_UPDATED,
                                         event: :enable_router_egress,
                                         id: item.interface_id)
    end
    
    # item created in db on queue 'item.id'
    def created_item(params)
      return if @items[params[:id]]
      return unless @active_route_links[params[:route_link_id]]

      internal_new_item(mw_class.new(params), {})
    end

    #
    # Overload helper methods:
    #

    # We should only active networks on this datapath that have
    # non-simulated/remote interfaces.
    #
    # Note: Replace by active segment once implemented.

    def activate_network_value(network_id, params)
      params[:route_id_list] = {}
    end

    def activate_network_update_item_proc(network_id, params)
      route_id_list = params[:route_id_list] || return

      Proc.new { |id, item|
        item.active_network = true
        route_id_list[item.id] = true
      }
    end

    def activate_route_link_value(route_link_id, params)
      params[:route_id_list] = {}
    end

    def activate_route_link_update_item_proc(route_link_id, params)
      route_id_list = params[:route_id_list] || return

      Proc.new { |id, item|
        item.active_route_link = true
        route_id_list[item.id] = true
      }
    end

  end

end
