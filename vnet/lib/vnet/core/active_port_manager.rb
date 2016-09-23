# -*- coding: utf-8 -*-

module Vnet::Core

  class ActivePortManager < Vnet::Core::ActiveManager

    include Vnet::Constants::ActivePort

    #
    # Events:
    #
    subscribe_event ACTIVE_PORT_INITIALIZED, :load_item
    subscribe_event ACTIVE_PORT_UNLOAD_ITEM, :unload_item
    subscribe_event ACTIVE_PORT_CREATED_ITEM, :created_item
    subscribe_event ACTIVE_PORT_DELETED_ITEM, :unload_item

    subscribe_event ACTIVE_PORT_ACTIVATE, :activate_port
    subscribe_event ACTIVE_PORT_DEACTIVATE, :deactivate_port

    #
    # Internal methods:
    #

    private

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
      when :id, :datapath_id, :port_name, :port_number
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
      item_class = detect_item_class(item_map.mode) || return

      item_class.new(dp_info: @dp_info, id: item_map[:id], map: item_map)
    end

    #
    # Create / Delete events:
    #

    # item created in db on queue 'item.id'
    def created_item(params)
      return if internal_detect_by_id(params)
      return if @datapath_info.nil? || params[:datapath_id] != @datapath_info.id

      internal_new_item(mw_class.new(params))
    end

    #
    # Port events:
    #

    # Port manager will always pass us properly sequenced
    # activate/deactivate port events, so it is safe to add/remove
    # flows and such independently of the item created/deleted events.

    # activate port on queue '[:port, port_number]'
    def activate_port(params)
      warn log_format_h("activating port", params)

      begin
        item_id = get_param_packed_id(params, :id, true, 32)

        port_name = get_param_string(params, :port_name)
        port_number = get_param_of_port(params, :port_number)

        if port_number != item_id
          return throw_param_error("mismatch between params id value and port_number", params, :id)
        end

        # If we already have this port, decide what to do.

        # Figure out what port type this is, and tell e.g. interface
        # port / tunnel manager.

        item_mode = detect_item_mode(port_name, port_number)

        add_port_flows(item_mode, port_number)

        # May need to do the creation using async in order to allow
        # deactivation of port if vnmgr is down.
        #
        # A list of ports in the process of creation might be needed.

        item_model = mw_class.create(
          datapath_id: @datapath_info.id,
          port_name: port_name,
          port_number: port_number,
          mode: item_mode
          )
      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    # deactivate port on queue '[:port, port_number]'
    def deactivate_port(params)
      debug log_format_h("deactivating port", params)

      begin
        item_id = get_param_packed_id(params, :id, true, 32)

        del_port_flows(item_id)

        mw_class.destroy(datapath_id: @datapath_info.id,
                         port_number: item_id)

      rescue Vnet::ParamError => e
        handle_param_error(e)
      end
    end

    #
    # Helper methods:
    #

    def detect_item_class(mode)
      case mode
      when MODE_LOCAL   then ActivePorts::Local
      when MODE_TUNNEL  then ActivePorts::Tunnel
      when MODE_UNKNOWN then ActivePorts::Unknown
      else
        nil
      end
    end

    def detect_item_mode(port_name, port_number)
      case
      when port_number == OFPP_LOCAL
        MODE_LOCAL
      when port_name =~ /^t-/
        MODE_TUNNEL
      else
        MODE_UNKNOWN
      end
    end

    def add_port_flows(mode, port_number)
      item_class = detect_item_class(mode) || return
      item_class.add_flows_for_id(@dp_info, port_number)
    end

    def del_port_flows(port_number)
      cookie = ActivePorts::Base.cookie_for_id(port_number)
      @dp_info.del_cookie(cookie)
    end

  end

end
