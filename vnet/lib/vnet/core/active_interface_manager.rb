# -*- coding: utf-8 -*-

module Vnet::Core

  class ActiveInterfaceManager < Vnet::Core::Manager

    #
    # Events:
    #

    subscribe_event ACTIVE_INTERFACE_INITIALIZED, :load_item
    subscribe_event ACTIVE_INTERFACE_UNLOAD_ITEM, :unload_item
    subscribe_event ACTIVE_INTERFACE_CREATED_ITEM, :created_item
    subscribe_event ACTIVE_INTERFACE_DELETED_ITEM, :unload_item

    subscribe_event ACTIVE_INTERFACE_UPDATED, :updated_item

    def activate_local_item(params)
      return if @datapath_info.nil? # Add error message...

      create_params = params.merge(datapath_id: @datapath_info.id)

      # Needs to be an event... or rather we need a way to disable an
      # id manually. Also this requires us to be able to insert an
      # event task in order to stay within this context and get the
      # return value.

      item_model = mw_class.create(create_params)
      return if item_model.nil? # Add error message...
      
      # Wait for loaded...
      item_model.to_hash
    end

    #
    # Internal methods:
    #

    private

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
      when :id, :interface_id, :datapath_id, :port_name, :label
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
      filter << {label: params[:label]} if params.has_key? :label
      filter
    end

    def item_initialize(item_map, params)
      item_class = ActiveInterfaces::Base
      item = item_class.new(dp_info: @dp_info, id: item_map[:id], map: item_map)
    end

    #
    # Create / Delete events:
    #

    # item created in db on queue 'item.id'
    def created_item(params)
      return if internal_detect_by_id(params)

      internal_new_item(mw_class.new(params), {})
    end

    # item updated in db on queue 'item.id'
    def updated_item(params)
      item = internal_detect_by_id(params) || return

      # Currently only allow updated change 'label', 'singular' and
      # 'port_name'.  

      item.port_name = params[:port_name]
      item.label = params[:label]
      item.singular = params[:singular]
    end

    #
    # Overload helper methods:
    #

  end

end
