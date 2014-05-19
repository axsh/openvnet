# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TranslationManager < Vnet::Openflow::Manager

    include Vnet::Constants::Translation
    include ActiveInterfaces

    #
    # Events:
    #
    subscribe_event TRANSLATION_INITIALIZED, :load_item
    subscribe_event TRANSLATION_UNLOAD_ITEM, :unload_item
    subscribe_event TRANSLATION_CREATED_ITEM, :created_item
    subscribe_event TRANSLATION_DELETED_ITEM, :unload_item

    subscribe_event TRANSLATION_ACTIVATE_INTERFACE, :activate_interface
    subscribe_event TRANSLATION_DEACTIVATE_INTERFACE, :deactivate_interface

    subscribe_event TRANSLATION_ADDED_STATIC_ADDRESS, :added_static_address
    subscribe_event TRANSLATION_REMOVED_STATIC_ADDRESS, :removed_static_address

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

    def select_filter_from_params(params)
      return if params.has_key?(:uuid) && params[:uuid].nil?

      create_batch(mw_class.batch, params[:uuid], query_filter_from_params(params))
    end

    def item_initialize(item_map, params)
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
      case item.mode
      when :static_address then load_static_addresses(item, item_map)
      end
    end

    # TRANSLATION_CREATED_ITEM on queue 'item.id'.
    def created_item(params)
      return if @items[params[:id]]
      return unless @active_interfaces[params[:interface_id]]

      internal_new_item(mw_class.new(params), {})
    end

    #
    # Translation events:
    #

    # load static addresses on queue 'item.id'.
    def load_static_addresses(item, item_map)
      item_map.batch.translation_static_addresses.commit.each { |translation|
        item.added_static_address(translation.id,
                                  translation.route_link_id,
                                  translation.ingress_ipv4_address,
                                  translation.egress_ipv4_address,
                                  translation.ingress_port_number,
                                  translation.egress_port_number)
      }
    end

    # TRANSLATION_ADDED_STATIC_ADDRESS on queue 'item.id'.
    def added_static_address(params)
      item_id = params[:id] || return
      item = @items[item_id] || return

      static_address_id = params[:static_address_id] || return
      ingress_ipv4_address = params[:ingress_ipv4_address] || return
      egress_ipv4_address = params[:egress_ipv4_address] || return
      ingress_port_number = params[:ingress_port_number] || return
      egress_port_number = params[:egress_port_number] || return

      item.added_static_address(static_address_id,
                                params[:route_link_id],
                                ingress_ipv4_address,
                                egress_ipv4_address,
                                ingress_port_number,
                                egress_port_number)
    end

    # TRANSLATION_REMOVED_STATIC_ADDRESS on queue 'item.id'.
    def removed_static_address(params)
      item_id = params[:id] || return
      item = @items[item_id] || return

      static_address_id = params[:static_address_id] || return
      
      item.removed_static_address(static_address_id)
    end

  end

end
