# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TranslationManager < Vnet::Manager
    include Vnet::Event::Dispatchable

    def initialize(params)
      super

      @interfaces = {}
    end

    #
    # Events:
    #
    subscribe_event INITIALIZED_TRANSLATION, :install_item

    subscribe_event TRANSLATION_ADDED_STATIC_ADDRESS, :added_static_address
    subscribe_event TRANSLATION_REMOVED_STATIC_ADDRESS, :removed_static_address

    def update(params)
      case params[:event]
      when :install_interface
        install_interface(params)
      when :remove_interface
        remove_interface(params)
      else
        nil
      end

      nil
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
      return false if params[:interface_id] && params[:interface_id] != item.interface_id
      true
    end

    def select_filter_from_params(params)
      case
      when params[:id]   then {:id => params[:id]}
      when params[:uuid] then params[:uuid]
      when params[:interface_id] then {:interface_id => params[:interface_id]}
      else
        # Any invalid params that should cause an exception needs to
        # be caught by the item_by_params_direct method.
        return nil
      end
    end

    def select_filter_from_params(params)
      return if params.has_key?(:uuid) && params[:uuid].nil?

      filters = []
      filters << {id: params[:id]} if params.has_key? :id
      filters << {interface_id: params[:interface_id]} if params.has_key? :interface_id

      create_batch(MW::Translation.batch, params[:uuid], filters)
    end

    def select_item(filter)
      # TODO: Load static addresses using events... (use array of addresses)
      filter.commit(fill: :translation_static_addresses)
    end

    def item_initialize(item_map, params)
      debug log_format("item initialize", item_map.inspect)

      item_class =
        case item_map.mode
        when 'static_address' then Translations::StaticAddress
        when 'vnet_edge'      then Translations::VnetEdgeHandler
        else
          return
        end

      item_class.new(dp_info: @dp_info,
                     manager: self,
                     map: item_map)
    end

    def initialized_item_event
      INITIALIZED_TRANSLATION
    end

    def create_item(params)
      @items[params[:id]] && return

      debug log_format("insert #{item.uuid}/#{item.id}")
    end

    def install_item(params)
      item_map = params[:item_map] || return
      item = (item_map.id && @items[item_map.id]) || return

      debug log_format("install #{item_map.uuid}/#{item_map.id}", "mode:#{item.mode}")

      case item.mode
      when :static_address then load_static_addresses(item, item_map)
      end

      item.try_install
    end

    def delete_item(item)
      @items.delete(item.id)

      item.try_uninstall
    end

    #
    # Event handlers:
    #

    def install_interface(params)
      return if params[:interface_id].nil?
      return if @interfaces.has_key? params[:interface_id]

      @interfaces[params[:interface_id]] = {
      }

      # Currently only support a single item with the same interface
      # id.
      item = item_by_params(interface_id: params[:interface_id])
    end

    def remove_interface(params)
      return if params[:interface_id].nil?

      @interfaces.delete(params[:interface_id])

      item = internal_detect(interface_id: params[:interface_id])

      delete_item(item) if item
    end

    #
    # Translation events:
    #

    # load static addresses on queue 'item.id'
    def load_static_addresses(item, item_map)
      item_map.batch.translation_static_addresses.commit.each { |translation|
        item.added_static_address(translation.id,
                                  translation.ingress_ipv4_address,
                                  translation.egress_ipv4_address)
      }
    end

    # TRANSLATION_ADDED_STATIC_ADDRESS on queue 'item.id'
    def added_static_address(params)
      item_id = params[:id] || return
      item = @items[item_id] || return

      static_address_id = params[:static_address_id] || return
      ingress_ipv4_address = params[:ingress_ipv4_address] || return
      egress_ipv4_address = params[:egress_ipv4_address] || return
      
      item.added_static_address(static_address_id, ingress_ipv4_address, egress_ipv4_address)
    end

  end

end
