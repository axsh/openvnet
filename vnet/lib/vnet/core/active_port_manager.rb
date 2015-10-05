# -*- coding: utf-8 -*-

module Vnet::Core

  class ActivePortManager < Vnet::Core::Manager

    include Vnet::Constants::ActivePort

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

    # TODO: Add do_initialize, clean up old port entries.

    def do_cleanup
      # Cleanup may be called before the manager is initialized.
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

    # Port manager will always pass us properly sequenced
    # activate/deactivate port events, so it is safe to add/remove
    # flows and such independently of the item created/deleted events.

    # activate port on queue '[:port, port_number]'
    def activate_port(params)
      warn log_format("activating port", params)

      port_name = params_string_n(params, :port_name) || return
      port_number = validate_port_number(params_value(params, :port_number)) || return

      if port_number != params_id_value(params)
        return params_error("mismatch between params id value and port_number", params)
      end

      # Check for conflicts.

      # If we already have this port, decide what to do.

      # Figure out what port type this is, and tell e.g. interface
      # port / tunnel manager.

      item_mode = detect_item_mode(port_name, port_number)

      add_port_flows(item_mode, port_number)

      # May need to do the creation using async in order to allow
      # deactivation of port if vnmgr is down.
      #
      # A list of ports in the process of creation might be needed.

      item_model = mw_class.create(datapath_id: @datapath_info.id,
                                   port_name: port_name,
                                   port_number: port_number,
                                   mode: item_mode)
    end

    # deactivate port on queue '[:port, port_number]'
    def deactivate_port(params)
      debug log_format("deactivating port", params)

      port_number = validate_port_number(params_id_value(params)) || return

      del_port_flows(item_mode, port_number)

      item_model = mw_class.destroy(datapath_id: @datapath_info.id,
                                    port_number: port_number)
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

    def del_port_flows(mode, port_number)
      cookie = ActivePorts::Base.cookie_for_id(port_number)
      @dp_info.del_cookie(cookie)
    end

    # TODO: Move the params methods to a manager helper module.

    def params_string(params, key)
      params[key] || params_error("missing string parameter #{key}", params)
      # Add type check.
    end

    def params_string_n(params, key)
      params[key] || params_error("missing string parameter #{key}", params)
      # Add type and not-empty check.
    end

    def params_value(params, key)
      params[key] || params_error("missing value parameter #{key}", params)
      # Add type check.
    end

    # We can pass id params as [:category, id_value] in cases where we
    # need event queues that do not apply to a specific item id.

    def params_id_value(params)
      p_id = params[:id] || params_error("missing parameter id", params)
      p_id[1] || params_error("missing second element in id array", params)
    end

    # Used for cases where the params is supposed to always contain a
    # certain parameter.
    def params_error(message, params)
      error log_format(message, params.inspect)
      caller.each { |str| error log_format(str) }

      # We return nil to ensure the callers properly handle the error.
      return nil
    end

    def validate_port_number(port_number)
      # TODO: Add verification.
      port_number
    end

  end

end
