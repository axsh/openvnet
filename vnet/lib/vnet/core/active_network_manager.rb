# -*- coding: utf-8 -*-

module Vnet::Core

  class ActiveNetworkManager < Vnet::Core::Manager

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event ACTIVE_NETWORK_INITIALIZED, :load_item
    subscribe_event ACTIVE_NETWORK_UNLOAD_ITEM, :unload_item
    subscribe_event ACTIVE_NETWORK_CREATED_ITEM, :created_item
    subscribe_event ACTIVE_NETWORK_DELETED_ITEM, :unload_item

    finalizer :do_cleanup

    def activate_local_item(params)
      create_params = params.merge(datapath_id: @datapath_info.id)

      # Needs to be an event... or rather we need a way to disable an
      # id manually. Also this requires us to be able to insert an
      # event task in order to stay within this context and get the
      # return value.

      item_model = mw_class.create(create_params)

      if item_model.nil?
        warn log_format("could not activate network", params.inspect)
        return
      end
      
      # Wait for loaded...
      item_model.to_hash
    end

    def deactivate_local_item(network_id)
      return if network_id.nil?

      # Do we need this?
      # item = internal_detect(network_id: network_id,
      #                        datapath_id: @datapath_info.id)
      # return if item.nil?

      mw_class.destroy(network_id: network_id,
                       datapath_id: @datapath_info.id)
      nil
    end

    #
    # Internal methods:
    #

    private

    def do_cleanup
      # Cleanup can be called before the manager is initialized.
      return if @datapath_info.nil?

      info log_format('cleaning up')

      begin
        mw_class.batch.dataset.where(datapath_id: @datapath_info.id).destroy.commit
      rescue NoMethodError => e
        info log_format(e.message, e.class.name)
      end

      info log_format('cleaned up')
    end

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
      # when :not_local
      #   proc { |id, item| value != item.network_id }
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
    # Overload helper methods:
    #

    # TODO: Move to a core-specific manager class:
    def params_valid_item?(params)
      return params[:id] &&
        params[:network_id] &&
        params[:datapath_id]
    end

    def params_current_datapath?(params)
      raise "params_current_datapath? assumes params[:datapath_id] is valid" unless params[:datapath_id]

      return params[:datapath_id] == @datapath_info.id
    end

  end

end
