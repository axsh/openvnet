# -*- coding: utf-8 -*-

module Vnet::Core

  class ActiveNetworkManager < Vnet::Core::ActiveManager

    #
    # Events:
    #
    subscribe_event ACTIVE_NETWORK_INITIALIZED, :load_item
    subscribe_event ACTIVE_NETWORK_UNLOAD_ITEM, :unload_item
    subscribe_event ACTIVE_NETWORK_CREATED_ITEM, :created_item
    subscribe_event ACTIVE_NETWORK_DELETED_ITEM, :unload_item

    subscribe_event ACTIVE_NETWORK_ACTIVATE, :activate_network
    subscribe_event ACTIVE_NETWORK_DEACTIVATE, :deactivate_network

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::ActiveNetwork
    end

    def initialized_item_event
      ACTIVE_NETWORK_INITIALIZED
    end

    def item_unload_event
      ACTIVE_NETWORK_UNLOAD_ITEM
    end

    # TODO: Add 'not_local/remote' filter.
    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :network_id, :datapath_id
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {network_id: params[:network_id]} if params.has_key? :network_id
      filter << {datapath_id: params[:datapath_id]} if params.has_key? :datapath_id

      filter
    end

    def item_initialize(item_map)
      return unless @datapath_info

      item_class =
        case item_map.datapath_id
        when nil               then ActiveNetworks::Base
        when @datapath_info.id then ActiveNetworks::Local
        else
          ActiveNetworks::Remote
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
    # Network events:
    #

    # activate network on queue '[:network, network_id]'
    def activate_network(params)
      debug log_format_h("activating network", params)

      begin
        options = {
          datapath_id: @datapath_info.id,
          network_id: get_param_packed_id(params)
        }

        mw_class.create(options)

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    # deactivate network on queue '[:network, network_id]'
    def deactivate_network(params)
      debug log_format_h("deactivating network", params)

      begin
        filter = {
          datapath_id: @datapath_info.id,
          network_id: get_param_packed_id(params)
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
      return params[:id] &&
        params[:network_id] &&
        params[:datapath_id]
    end

  end

end
