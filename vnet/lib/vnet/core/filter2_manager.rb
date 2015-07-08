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

    subscribe_event FILTER_ACTIVATE_INTERFACE, :activate_interface
    subscribe_event FILTER_DEACTIVATE_INTERFACE, :deactivate_interface

    subscribe_event FILTER_ADDED_STATIC, :added_static_address
    subscribe_event FILTER_REMOVED_STATIC, :removed_static_address

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
      FILTERN_INITIALIZED
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
        when MODE_STATIC_FILTER then Filter::StaticFilter
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
      when :static_filter then load_static_filter(item, item_map)
      end
    end

    # FILTER_CREATED_ITEM on queue 'item.id'.
    def created_item(params)
      return if internal_detect_by_id(params)
      return if params[:interface_id].nil?
      return if @active_interfaces[params[:interface_id]].nil?

      internal_new_item(mw_class.new(params))
    end

    #
    # Filter events:
    # to change

    # load static filter on queue 'item.id'.
    def load_static_filter(item, item_map)
      item_map.batch.static_filter.commit.each { |filter|
        item.added_static_filter(filter.id)
      }
    end

    # TRANSLATION_ADDED_STATIC_ADDRESS on queue 'item.id'.
    def added_static_filter(params)
      item = internal_detect_by_id_with_error(params) || return

      static_filter_id = get_param_id(params, :static_filter_id) || return

        return
      end


      item.added_static_address(static_filter_id)
    end

    # FILTER_REMOVED_STATIC on queue 'item.id'.
    def removed_static_filter(params)
      item = internal_detect_by_id(params) || return

      static_filter_id = params[:static_filter_id] || return

      item.removed_static_filter(static_filter_id)
    end

  end

end
