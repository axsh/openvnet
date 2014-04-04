# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager < Vnet::Manager

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

      routes.uniq { |route_map|
        route_map.route_link_id
      }.each { |route_map|
        @dp_info.router_manager.async.retrieve(id: route_map.route_link_id)
      }
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

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

      self.retrieve(params)
    end

    def install_item(params)
      item_map = params[:item_map] || return
      item = (item_map.id && @items[item_map.id]) || return

      debug log_format("install #{item.uuid}/#{item.id}")

      item.install

      @dp_info.interface_manager.async.retrieve(id: item.interface_id)
      @dp_info.interface_manager.async.update_item(event: :enable_router_egress,
                                                   id: item.interface_id)
    end
    
    def delete_item(params)
      item = @items.delete(params[:id])

      debug log_format("delete #{item.uuid}/#{item.id}")

      item.uninstall
    end

  end

end
