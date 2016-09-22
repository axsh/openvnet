# -*- coding: utf-8 -*-

module Vnet::Core

  class TranslationManager < Vnet::Core::Manager

    include Vnet::Constants::Translation
    include ActiveInterfaceEvents

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event TRANSLATION_INITIALIZED, :load_item
    subscribe_event TRANSLATION_UNLOAD_ITEM, :unload_item
    subscribe_event TRANSLATION_CREATED_ITEM, :created_item
    subscribe_event TRANSLATION_DELETED_ITEM, :unload_item

    subscribe_event TRANSLATION_ADDED_STATIC_ADDRESS, :added_static_address
    subscribe_event TRANSLATION_REMOVED_STATIC_ADDRESS, :removed_static_address

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
      MW::Translation
    end

    def initialized_item_event
      TRANSLATION_INITIALIZED
    end

    def item_unload_event
      TRANSLATION_UNLOAD_ITEM
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
        when MODE_STATIC_ADDRESS then Translations::StaticAddress
        when MODE_VNET_EDGE      then Translations::VnetEdgeHandler
        else
          return
        end

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_pre_install(item, item_map)
      case item
      when Translations::StaticAddress then load_static_addresses(item, item_map)
      end
    end

    # TRANSLATION_CREATED_ITEM on queue 'item.id'.
    def created_item(params)
      return if internal_detect_by_id(params)

      interface_id = params[:interface_id]
      return if interface_id.nil? || @active_interfaces[interface_id].nil?

      internal_new_item(mw_class.new(params))
    end

    #
    # Translation events:
    #

    # load static addresses on queue 'item.id'.
    def load_static_addresses(item, item_map)
      item_map.batch.translation_static_addresses.commit.each { |params|
        begin
          item.added_static_address(
            get_param_id(params, :id),
            get_param_id(params, :route_link_id),
            get_param_ipv4_address(params, :ingress_ipv4_address),
            get_param_ipv4_address(params, :egress_ipv4_address),
            get_param_tp_port(params, :ingress_port_number, false),
            get_param_tp_port(params, :egress_port_number, false)
            )
        rescue Vnet::ParamError => e
          handle_param_error(e)
        end
      }
    end

    # TRANSLATION_ADDED_STATIC_ADDRESS on queue 'item.id'.
    def added_static_address(params)
      item = internal_detect_by_id_with_error(params) || return

      begin
        item.added_static_address(
          get_param_id(params, :static_address_id),
          get_param_id(params, :route_link_id),
          get_param_ipv4_address(params, :ingress_ipv4_address),
          get_param_ipv4_address(params, :egress_ipv4_address),
          get_param_tp_port(params, :ingress_port_number, false),
          get_param_tp_port(params, :egress_port_number, false)
          )
      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    # TRANSLATION_REMOVED_STATIC_ADDRESS on queue 'item.id'.
    def removed_static_address(params)
      item = internal_detect_by_id(params) || return

      begin
        item.removed_static_address(get_param_id(params, :static_address_id))
      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

  end

end
