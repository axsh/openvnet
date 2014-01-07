# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouterManager < Manager

    #
    # Events:
    #
    subscribe_event ADDED_ROUTER, :create_item
    subscribe_event REMOVED_ROUTER, :delete_item
    subscribe_event INITIALIZED_ROUTER, :install_item

    def update(params)
      case params[:event]
      when :activate_route
        activate_route(params)
      end

      nil
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} router_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

    def select_item(filter)
      MW::RouteLink.batch[filter].commit(fill: :routes)
    end

    def item_initialize(item_map, params)
      Routers::RouteLink.new(dp_info: @dp_info, manager: self, map: item_map)
    end

    def initialized_item_event
      INITIALIZED_ROUTER
    end

    def create_item(params)
      item = @items[params[:item_map].id]
      return unless item

      item
    end

    def install_item(params)
      item = @items[params[:item_map].id]
      return nil if item.nil?

      item.install

      @dp_info.datapath_manager.async.update(event: :activate_route_link,
                                             route_link_id: item.id)

      debug log_format("install #{item.uuid}/#{item.id}")

      params[:item_map].routes.each { |route_map|
        @dp_info.route_manager.async.insert(route_map)
      }

      item
    end

    def delete_item(item)
      @items.delete(item.id)

      item.uninstall
      item
    end

    #
    # Events:
    #

    def activate_route(params)
      item = internal_detect(id: params[:id])

      return if item.nil?
      return if params[:route_id].nil?

      item.add_active_route(params[:route_id])
    end

  end

end
