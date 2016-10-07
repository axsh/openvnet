# -*- coding: utf-8 -*-

module Vnet::Core

  class ActiveInterfaceManager < Vnet::Core::Manager

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event ACTIVE_INTERFACE_INITIALIZED, :load_item
    subscribe_event ACTIVE_INTERFACE_UNLOAD_ITEM, :unload_item
    subscribe_event ACTIVE_INTERFACE_CREATED_ITEM, :created_item
    subscribe_event ACTIVE_INTERFACE_DELETED_ITEM, :unload_item

    subscribe_event ACTIVE_INTERFACE_UPDATED, :updated_item

    finalizer :do_cleanup

    def activate_local_item(params)
      create_params = params.merge(datapath_id: @datapath_info.id)

      # Needs to be an event... or rather we need a way to disable an
      # id manually. Also this requires us to be able to insert an
      # event task in order to stay within this context and get the
      # return value.

      item_model = mw_class.create(create_params)

      if item_model.nil?
        warn log_format_h("could not activate interface", params)
        return
      end

      # Wait for loaded...
      item_model.to_hash
    end

    def deactivate_local_item(interface_id)
      return if interface_id.nil?

      # Do we need this?
      # item = internal_detect(interface_id: interface_id,
      #                        datapath_id: @datapath_info.id)
      # return if item.nil?

      mw_class.destroy(interface_id: interface_id,
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
      MW::ActiveInterface
    end

    def initialized_item_event
      ACTIVE_INTERFACE_INITIALIZED
    end

    def item_unload_event
      ACTIVE_INTERFACE_UNLOAD_ITEM
    end

    # TODO: Add 'not_local/remote' filter.
    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :interface_id, :datapath_id, :port_name, :port_number, :label, :singular, :enable_routing
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
      filter << {interface_id: params[:interface_id]} if params.has_key? :interface_id
      filter << {datapath_id: params[:datapath_id]} if params.has_key? :datapath_id

      filter << {port_name: params[:port_name]} if params.has_key? :port_name
      filter << {port_number: params[:port_number]} if params.has_key? :port_number

      filter << {label: params[:label]} if params.has_key? :label
      filter << {singular: params[:singular]} if params.has_key? :singular
      filter << {enable_routing: params[:enable_routing]} if params.has_key? :enable_routing
      filter
    end

    def item_initialize(item_map)
      return unless @datapath_info

      item_class =
        case item_map.datapath_id
        when nil               then ActiveInterfaces::Base
        when @datapath_info.id then ActiveInterfaces::Local
        else
          ActiveInterfaces::Remote
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

      internal_new_item(mw_class.new(params))
    end

    # item updated in db on queue 'item.id'
    def updated_item(params)
      return unless params_valid_item? params
      item = internal_detect_by_id(params)

      if item.nil?
        # TODO: Check if we need this item.
        internal_new_item(mw_class.new(params))
        return
      end

      # Currently only allow updated to change 'label', 'singular' and
      # 'port_name'.
      # item.label = params[:label]
      # item.singular = params[:singular]

      # TODO: Update this properly.
      item.enable_routing = params[:enable_routing]

      debug log_format("updated " + item.pretty_id, item.pretty_properties)
    end

    #
    # Overload helper methods:
    #

    # TODO: Move to a core-specific manager class:
    def params_valid_item?(params)
      return @datapath_info &&
        params[:id] &&
        params[:interface_id] &&
        params[:datapath_id]
    end

    def params_current_datapath?(params)
      raise "params_current_datapath? assumes params[:datapath_id] is valid" unless params[:datapath_id]
      raise "params_current_datapath? assumes @datapath_info.id is valid" unless @datapath_info && @datapath_info.id

      return params[:datapath_id] == @datapath_info.id
    end

  end

end
