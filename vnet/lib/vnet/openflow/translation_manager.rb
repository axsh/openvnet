# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TranslationManager < Manager
    include Vnet::Event::Dispatchable

    #
    # Events:
    #
    subscribe_event INITIALIZED_TRANSLATION, :install_item

    def update(params)
      # case params[:event]
      #   nil
      # end

      nil
    end

    #
    # Refactor:
    #

    # def update_translation_map
    #   @translation_map = Vnet::ModelWrappers::VlanTranslation.batch.all.commit
    # end

    # def network_to_vlan(network_id)
    #   entry = @translation_map.find { |t| t.network_id == network_id }
    #   entry && entry.vlan_id
    # end

    # def vlan_to_network(vlan_vid)
    #   entry = @translation_map.find { |t| t.vlan_id == vlan_vid }
    #   entry && entry.network_id
    # end

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
      true
    end
    
    def select_filter_from_params(params)
      case
      when params[:id]   then {:id => params[:id]}
      when params[:uuid] then params[:uuid]
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
    # Refactor:
    #

    # def add_handler(params)
    #   info log_format("install handlers", params[:mode])
    #   item = translation_handler_initialize(params)

    #   return nil if item.nil?

    #   @items[item.id] = item
    # end

    # def initialize_handlers
    #   return unless @dp_info.datapath.datapath_map.node_id == 'edge'
    #   add_handler(mode: :vnet_edge, dp_info: @dp_info)
    # end

  end

end
