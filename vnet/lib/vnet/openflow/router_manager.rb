# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouterManager < Vnet::Manager

    #
    # Events:
    #
    subscribe_event ROUTER_INITIALIZED, :install_item
    subscribe_event ROUTER_CREATED_ITEM, :created_item
    subscribe_event ROUTER_DELETED_ITEM, :unload_item

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def initialized_item_event
      ROUTER_INITIALIZED
    end

    def select_filter_from_params(params)
      return nil if params.has_key?(:uuid) && params[:uuid].nil?

      filters = []
      filters << {id: params[:id]} if params.has_key? :id

      create_batch(MW::RouteLink.batch, params[:uuid], filters)
    end

    def item_initialize(item_map, params)
      Routers::RouteLink.new(dp_info: @dp_info,
                             manager: self,
                             map: item_map)
    end

    #
    # Create / Delete events:
    #

    def created_item(params)
      # Do nothing.
    end

    def install_item(params)
      item_map = params[:item_map] || return
      item = (item_map.id && @items[item_map.id]) || return

      debug log_format("install #{item.uuid}/#{item.id}")

      item.try_install

      @dp_info.route_manager.publish(ROUTE_ACTIVATE_ROUTE_LINK,
                                     id: :route_link,
                                     route_link_id: item.id)
      @dp_info.datapath_manager.publish(ACTIVATE_ROUTE_LINK_ON_HOST,
                                        id: :route_link,
                                        route_link_id: item.id)
    end

    def unload_item(item)
      @items.delete(item.id)

      item.try_uninstall

      @dp_info.route_manager.publish(ROUTE_DEACTIVATE_ROUTE_LINK,
                                     id: :route_link,
                                     route_link_id: item.id)
      @dp_info.datapath_manager.publish(DEACTIVATE_ROUTE_LINK_ON_HOST,
                                        id: :route_link,
                                        route_link_id: item.id)
    end

    #
    # Events:
    #

  end

end
