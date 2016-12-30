# -*- coding: utf-8 -*-

module Vnet::Core

  class Filter2Manager < Vnet::Core::Manager

    include Vnet::Constants::Filter
    include ActiveInterfaceEvents

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event FILTER_INITIALIZED, :load_item
    subscribe_event FILTER_UNLOAD_ITEM, :unload_item
    subscribe_event FILTER_CREATED_ITEM, :created_item
    subscribe_event FILTER_DELETED_ITEM, :unload_item
    subscribe_event FILTER_UPDATED, :updated_item

    subscribe_event FILTER_ADDED_STATIC, :added_static
    subscribe_event FILTER_REMOVED_STATIC, :removed_static

    subscribe_event ACTIVATE_INTERFACE, :activate_interface
    subscribe_event DEACTIVATE_INTERFACE, :deactivate_interface

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::Filter
    end

    def initialized_item_event
      FILTER_INITIALIZED
    end

    def item_unload_event
      FILTER_UNLOAD_ITEM
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid, :interface_id
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {interface_id: params[:interface_id]} if params.has_key? :interface_id
      filter
    end

    def item_initialize(item_map)
      item_class =
        case item_map.mode
        when MODE_STATIC then Filters::Static
        else
          return
        end

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_pre_install(item, item_map)
      case item.mode
      when :static then load_static(item_map)
      end
    end

    # FILTER_CREATED_ITEM on queue 'item.id'.
    def created_item(params)
      return if internal_detect_by_id(params)
      return if @active_interfaces[get_param_id(params, :interface_id)].nil?

      internal_new_item(mw_class.new(params))
    end

    def updated_item(params)
      id = params.fetch(:id) || return

      item = internal_detect(id: id)
      return if item.nil?

      item.update(params)
    end

    #
    # Filter events:
    # to change

    # load static filter on queue 'item.id'.
    def load_static(item_map)
      item_map.batch.filter_statics.commit.each { |filter|
        model_hash = filter.to_hash.merge(id: item_map.id,
                                          static_id: filter.id)

        added_static(model_hash)
      }
    end

    # FILTER_ADDED_STATIC on queue 'item.id'.
    def added_static(params)
      item = internal_detect_by_id_with_error(params) || return
      begin
        item.added_static(
          get_param_id(params, :static_id),
          get_param_ipv4_address(params, :ipv4_src_address),
          get_param_ipv4_address(params, :ipv4_dst_address),
          get_param_int(params, :ipv4_src_prefix),
          get_param_int(params, :ipv4_dst_prefix),
          get_param_int(params, :port_src, false),
          get_param_int(params, :port_dst, false),
          get_param_string(params, :protocol),
          get_param(params, :passthrough)
        )
      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    # FILTER_REMOVED_STATIC on queue 'item.id'.
    def removed_static(params)
      item = internal_detect_by_id(params) || return

      begin
        item.removed_static(get_param_id(params, :static_id))
      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

  end

end
