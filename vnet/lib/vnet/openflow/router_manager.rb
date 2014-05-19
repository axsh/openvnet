# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouterManager < Vnet::Openflow::Manager

    #
    # Events:
    #
    subscribe_event ROUTER_INITIALIZED, :load_item
    subscribe_event ROUTER_UNLOAD_ITEM, :unload_item
    subscribe_event ROUTER_CREATED_ITEM, :created_item
    subscribe_event ROUTER_DELETED_ITEM, :deleted_item

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::RouteLink
    end

    def initialized_item_event
      ROUTER_INITIALIZED
    end

    def item_unload_event
      ROUTER_UNLOAD_ITEM
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter
    end

    def select_filter_from_params(params)
      return if params.has_key?(:uuid) && params[:uuid].nil?

      create_batch(mw_class.batch, params[:uuid], query_filter_from_params(params))
    end

    def item_initialize(item_map, params)
      item_class = Routers::RouteLink

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_post_install(item, item_map)
      @dp_info.route_manager.publish(ROUTE_ACTIVATE_ROUTE_LINK,
                                     id: :route_link,
                                     route_link_id: item.id)
      @dp_info.datapath_manager.publish(ACTIVATE_ROUTE_LINK_ON_HOST,
                                        id: :route_link,
                                        route_link_id: item.id)
    end

    def item_post_uninstall(item)
      @dp_info.route_manager.publish(ROUTE_DEACTIVATE_ROUTE_LINK,
                                     id: :route_link,
                                     route_link_id: item.id)
      @dp_info.datapath_manager.publish(DEACTIVATE_ROUTE_LINK_ON_HOST,
                                        id: :route_link,
                                        route_link_id: item.id)
    end

    # ROUTER_CREATED_ITEM on queue 'item.id'.
    def created_item(params)
      # Do nothing.
    end

    #
    # Events:
    #

  end

end
