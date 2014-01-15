# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager < Manager

    #
    # Events:
    #
    subscribe_event ADDED_ROUTE, :create_item
    subscribe_event REMOVED_ROUTE, :delete_item
    subscribe_event INITIALIZED_ROUTE, :install_item

    #
    # Refactor:
    #

    def prepare_network(network_map, dp_map)
      routes = network_map.batch.routes.commit
      return if routes.nil?

      routes.map { |route_map|
      #   route_map.route_link_id
      # }.uniq { |route_link_id|
      #   @dp_info.router_manager.async.retrieve(id: route_link_id)
        item_by_params(id: route_map.id)
      }
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} route_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid

      true
    end

    def select_filter_from_params(params)
      return nil if params.has_key?(:uuid) && params[:uuid].nil?

      filters = []
      filters << {id: params[:id]} if params.has_key? :id

      create_batch(MW::Route.batch, params[:uuid], filters)
    end

    def select_item(filter)
      filter.commit
    end

    def item_initialize(item_map, params)
      Routes::Base.new(dp_info: @dp_info,
                       manager: self,
                       map: item_map)
    end

    def initialized_item_event
      INITIALIZED_ROUTE
    end

    #
    # Create / Delete interfaces:
    #

    def create_item(params)
      return if @items[params[:id]]

      item = self.item(params)
      return unless item

      item
    end

    def install_item(params)
      item_map = params[:item_map]
      item = @items[item_map.id]
      return nil if item.nil?

      debug log_format("install #{item_map.uuid}/#{item_map.id}")

      item.install

      @dp_info.interface_manager.async.retrieve(id: item.interface_id)
      @dp_info.interface_manager.async.update_item(event: :enable_router_egress,
                                                   id: item.interface_id)

      item
    end
    
    def delete_item(params)
      item = @items.delete(params[:id])

      debug log_format("delete #{item.uuid}/#{item.id}")

      item.uninstall
      item
    end

  end

end
