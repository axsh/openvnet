# -*- coding: utf-8 -*-

module Vnet::Core

  class ActivePortManager < Vnet::Core::Manager

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event ACTIVE_PORT_INITIALIZED, :load_item
    subscribe_event ACTIVE_PORT_UNLOAD_ITEM, :unload_item
    subscribe_event ACTIVE_PORT_CREATED_ITEM, :created_item
    subscribe_event ACTIVE_PORT_DELETED_ITEM, :unload_item

    subscribe_event ACTIVE_PORT_ACTIVATE, :activate_port
    subscribe_event ACTIVE_PORT_DEACTIVATE, :deactivate_port

    finalizer :do_cleanup

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
      MW::ActivePort
    end

    def initialized_item_event
      ACTIVE_PORT_INITIALIZED
    end

    def item_unload_event
      ACTIVE_PORT_UNLOAD_ITEM
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :port_id, :datapath_id, :port_name, :port_number
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {datapath_id: params[:datapath_id]} if params.has_key? :datapath_id

      filter << {port_name: params[:port_name]} if params.has_key? :port_name
      filter << {port_number: params[:port_number]} if params.has_key? :port_number
      filter
    end

    def item_initialize(item_map)
      item_class = ActivePorts::Base

      item = item_class.new(dp_info: @dp_info, id: item_map[:id], map: item_map)
    end

    #
    # Create / Delete events:
    #

    # item created in db on queue 'item.id'
    def created_item(params)
      return if internal_detect_by_id(params)
      return if params[:datapath_id] != @datapath_info.id

      internal_new_item(mw_class.new(params))
    end

    #
    # Port events:
    #

    # activate port on queue '[:port, port_number]'
    def activate_port(params)
      warn log_format("XXXXXXXXXXX", params)

      # Validate, etc...

      port_name = params[:port_name]
      port_number = params[:port_number]

      # Validate port_number matches port_number in :id.

      # Check for conflicts.

      item_model = mw_class.create(datapath_id: @datapath_info.id,
                                   port_name: port_name,
                                   port_number: port_number)
    end

    # deactivate port on queue '[:port, port_number]'
    def deactivate_port(params)
      warn log_format("YYYYYYYYYYY", params)

      # Validate, etc...

      port_number = params[:id][1]

      # Check for conflicts.

      item_model = mw_class.destroy(datapath_id: @datapath_info.id,
                                    port_number: port_number)
    end

  end

end
