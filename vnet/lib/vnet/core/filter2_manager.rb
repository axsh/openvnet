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

    subscribe_event FILTER_ADDED_STATIC, :added_static
    subscribe_event FILTER_REMOVED_STATIC, :removed_static

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
      when :static then load_static(item, item_map)
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
    def load_static(item, item_map)
      item_map.batch.filter_statics.commit.each { |filter|
        item.added_static(filter.id,
                          filter.ipv4_address,
                          filter.port_number
                         )
      }
    end

    # FILTER_ADDED_STATIC on queue 'item.id'.
    def added_static(params)            
      item = internal_detect_by_id_with_error(params) || return

      static_id = get_param_id(params, :static_id) || return

      ipv4_address = get_param_id(params, :ipv4_address) || return

      port_number = get_param_id(params, :port_number, false) || return
      
      item.added_static(static_id,
                        ipv4_address,
                        port_number
                       )
    end

    # FILTER_REMOVED_STATIC on queue 'item.id'.
    def removed_static(params)
      item = internal_detect_by_id(params) || return

      static_id = params[:static_id] || return

      item.removed_static(static_id)
    end

  end

end
