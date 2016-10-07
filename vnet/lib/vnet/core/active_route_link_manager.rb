# -*- coding: utf-8 -*-

module Vnet::Core

  class ActiveRouteLinkManager < Vnet::Core::ActiveManager

    #
    # Events:
    #
    subscribe_event ACTIVE_ROUTE_LINK_INITIALIZED, :load_item
    subscribe_event ACTIVE_ROUTE_LINK_UNLOAD_ITEM, :unload_item
    subscribe_event ACTIVE_ROUTE_LINK_CREATED_ITEM, :created_item
    subscribe_event ACTIVE_ROUTE_LINK_DELETED_ITEM, :unload_item

    subscribe_event ACTIVE_ROUTE_LINK_ACTIVATE, :activate_route_link
    subscribe_event ACTIVE_ROUTE_LINK_DEACTIVATE, :deactivate_route_link

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::ActiveRouteLink
    end

    def initialized_item_event
      ACTIVE_ROUTE_LINK_INITIALIZED
    end

    def item_unload_event
      ACTIVE_ROUTE_LINK_UNLOAD_ITEM
    end

    # TODO: Add 'not_local/remote' filter.
    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :route_link_id, :datapath_id
        proc { |id, item| value == item.send(filter) }
      # when :not_local
      #   proc { |id, item| value != item.route_link_id }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {route_link_id: params[:route_link_id]} if params.has_key? :route_link_id
      filter << {datapath_id: params[:datapath_id]} if params.has_key? :datapath_id

      filter
    end

    def item_initialize(item_map)
      return unless @datapath_info

      item_class =
        case item_map.datapath_id
        when nil               then ActiveRouteLinks::Base
        when @datapath_info.id then ActiveRouteLinks::Local
        else
          ActiveRouteLinks::Remote
        end

      item = item_class.new(dp_info: @dp_info, id: item_map[:id], map: item_map)
    end

    #
    # Create / Delete events:
    #

    # item created in db on queue 'item.id'
    def created_item(params)
      return unless params_valid_item? params
      return if internal_detect_by_id(params)

      # Only load local and those of interest.

      internal_new_item(mw_class.new(params))
    end

    #
    # Route Link events:
    #

    # activate route link on queue '[:route_link, route_link_id]'
    def activate_route_link(params)
      debug log_format_h("activating route link", params)

      begin
        options = {
          datapath_id: @datapath_info.id,
          route_link_id: get_param_packed_id(params)
        }

        mw_class.create(options)

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    # deactivate route link on queue '[:route_link, route_link_id]'
    def deactivate_route_link(params)
      debug log_format_h("deactivating route link", params)

      begin
        filter = {
          datapath_id: @datapath_info.id,
          route_link_id: get_param_packed_id(params)
        }

        mw_class.destroy(filter)

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    #
    # Overload helper methods:
    #

    # TODO: Move to a core-specific manager class:
    def params_valid_item?(params)
      params[:id] &&
        params[:route_link_id] &&
        params[:datapath_id]
    end

  end

end
