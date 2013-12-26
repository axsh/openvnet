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
      MW::RouteLink.batch[filter].commit
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

      debug log_format("insert #{item.uuid}/#{item.id}")
      item
    end

    def install_item(params)
      item = @items[params[:item_map].id]
      return nil if item.nil?

      item.install

      debug log_format("install #{item.uuid}/#{item.id}")
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

  end

end
