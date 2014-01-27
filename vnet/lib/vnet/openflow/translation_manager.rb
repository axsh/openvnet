# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TranslationManager < Manager
    include Vnet::Event::Dispatchable

    def initialize(params)
      super

      @interfaces = {}
    end

    #
    # Events:
    #
    subscribe_event INITIALIZED_TRANSLATION, :install_item

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

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} translation_manager: #{message}" + (values ? " (#{values})" : '')
    end

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

    def select_item(filter)
      MW::Translation.batch[filter].commit(fill: :translate_static_addresses)
    end

    def item_initialize(item_map)
      params = {
        dp_info: @dp_info,
        manager: self,
        map: item_map
      }

      debug log_format("item initialize", item_map.inspect)

      case item_map.mode && item_map.mode.to_sym
      when :static_address then Translations::StaticAddress.new(params)
      when :vnet_edge      then Translations::VnetEdgeHandler.new(params)
      else
        nil
      end
    end

    def initialized_item_event
      INITIALIZED_TRANSLATION
    end

    def create_item(params)
      item = @items[params[:item_map].id]
      return unless item

      debug log_format("insert #{item.uuid}/#{item.id}")

      item
    end

    def install_item(params)
      item_map = params[:item_map]
      item = @items[item_map.id]
      return nil if item.nil?

      debug log_format("install #{item_map.uuid}/#{item_map.id}", "mode:#{item.mode}")

      item.install

      item
    end

    def delete_item(item)
      @items.delete(item.id)

      item.uninstall
      item
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

  end

end
