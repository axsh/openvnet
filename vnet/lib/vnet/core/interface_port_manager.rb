# -*- coding: utf-8 -*-

module Vnet::Core

  class InterfacePortManager < Vnet::Core::Manager

    include ActivePortEvents

    #
    # Events:
    #

    subscribe_event INTERFACE_PORT_INITIALIZED, :load_item
    subscribe_event INTERFACE_PORT_UNLOAD_ITEM, :unload_item
    subscribe_event INTERFACE_PORT_CREATED_ITEM, :created_item
    subscribe_event INTERFACE_PORT_DELETED_ITEM, :unload_item

    subscribe_event INTERFACE_PORT_UPDATED, :updated_item

    subscribe_event INTERFACE_PORT_ACTIVATE, :activate_port
    subscribe_event INTERFACE_PORT_DEACTIVATE, :deactivate_port

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::InterfacePort
    end

    def initialized_item_event
      INTERFACE_PORT_INITIALIZED
    end

    def item_unload_event
      INTERFACE_PORT_UNLOAD_ITEM
    end

    def initialized_datapath_info
      info log_format("updating items with new datapath_info")

      # TODO: Update items...
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :interface_id, :datapath_id, :port_name, :singular
        proc { |id, item| value == item.send(filter) }
      when :allowed_datapath
        proc { |id, item| item.allowed_datapath? }
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
      filter << {singular: params[:singular]} if params.has_key? :singular

      if params.has_key? :allowed_datapath
        filter << Sequel.|({ datapath_id: nil },
                           { datapath_id: @datapath_info && @datapath_info.id })
      end

      filter
    end

    def item_initialize(item_map)
      return unless @datapath_info

      item_class = InterfacePorts::Base

      item = item_class.new(dp_info: @dp_info,
                            datapath_info: @datapath_info,
                            id: item_map[:id],
                            map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_pre_install(item, item_map)
      if item.port_name
        @active_ports.detect { |port_number, active_port|
          item.port_name == active_port[:port_name] && item.allowed_datapath?
        }.tap { |port_number, active_port|
          next unless port_number && active_port

          item.port_number = port_number

          # TODO: Load local interface:
          # @dp_info.port_manager.publish(PORT_ATTACH_INTERFACE,
          #                               id: port_number,
          #                               interface: item_to_hash(item))
        }
      end
    end

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

      item.singular = params[:singular]
      item.port_name = params[:port_name]

      # TODO: Update port on port name change.

      debug log_format("updated " + item.pretty_id, item.pretty_properties)
    end

    #
    # Overload helper methods:
    #

    # TODO: Move to a core-specific manager class:
    def params_valid_item?(params)
      return @datapath_info &&
        params[:id] &&
        params[:interface_id]
        params[:datapath_id]
    end

    def params_current_datapath?(params)
      raise "params_current_datapath? assumes params[:datapath_id] is valid" unless params[:datapath_id]
      raise "params_current_datapath? assumes @datapath_info.id is valid" unless @datapath_info && @datapath_info.id

      return params[:datapath_id] == @datapath_info.id
    end

    #
    # Overload helper methods:
    #

    def activate_port_query(state_id, params)
      { port_name: params[:port_name],
        allowed_datapath: true
      }
    end

    def activate_port_match_proc(state_id, params)
      # TODO: Check port_name validity...
      port_name = params[:port_name] || return
      datapath_id = @datapath_info && @datapath_info.id

      Proc.new { |id, item|
        item.port_name == port_name && item.allowed_datapath?
      }
    end

    def activate_port_value(port_number, params)
      port_name = params[:port_name] || return

      { port_name: port_name }
    end

    def activate_port_update_item_proc(port_number, params)
      port_name = params[:port_name] || return

      Proc.new { |id, item|
        # publish(INTERFACE_PORT_UPDATE_PORT_NUMBER,
        #         id: id,
        #         port_number: port_number)
      }
    end

  end

end
