# -*- coding: utf-8 -*-

module Vnet::Core

  class RouterManager < Vnet::Core::Manager

    #
    # Events:
    #
    event_handler_default_drop_all

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

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter
    end

    def item_initialize(item_map)
      item_class = Routers::RouteLink

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_post_install(item, item_map)
      @dp_info.active_route_link_manager.publish(ACTIVE_ROUTE_LINK_ACTIVATE,
                                                 id: [:route_link, item.id])
      @dp_info.route_manager.publish(ROUTE_ACTIVATE_ROUTE_LINK,
                                     id: :route_link,
                                     route_link_id: item.id)
      @dp_info.datapath_manager.publish(ACTIVATE_ROUTE_LINK_ON_HOST,
                                        id: :route_link,
                                        route_link_id: item.id)
    end

    def item_post_uninstall(item)
      @dp_info.active_route_link_manager.publish(DEACTIVE_ROUTE_LINK_ACTIVATE,
                                                 id: [:route_link, item.id])
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
