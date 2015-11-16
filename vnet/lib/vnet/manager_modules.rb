# -*- coding: utf-8 -*-

module Vnet

  #
  # Update item states:
  #

  module UpdateItemStates
    # subscribe_event FOO_UPDATE_ITEM_STATES, :update_item_states

    def initialize(*args, &block)
      super
      @update_item_states = {}
    end

    private

    # Requires queue ':update_item_states'.
    def update_item_state(item)
      # Must be implemented by manager
      raise NotImplementedError
    end

    # Returns FOO_UPDATE_ITEM_STATES.
    def update_item_states_event
      # Must be implemented by manager
      raise NotImplementedError
    end

    def add_item_id_to_update_queue(item_id)
      raise ArgumentError, 'item id of nil not allowed' if item_id.nil?

      should_publish = @update_item_states.empty?
      @update_item_states[item_id] = true

      should_publish &&
        publish(update_item_states_event, id: :update_item_states)
    end

    def add_item_ids_to_update_queue(item_ids)
      raise ArgumentError, 'item id of nil not allowed' if item_ids.index(nil)

      should_publish = @update_item_states.empty?

      item_ids.select { |item_id|
        @update_item_states[item_id].nil?
      }.each { |item_id|
        @update_item_states[item_id] = true
      }

      should_publish &&
        publish(update_item_states_event, id: :update_item_states)
    end

    # FOO_UPDATE_ITEM_STATES on queue ':update_item_states'
    def update_item_states(params)
      while !@update_item_states.empty?
        item_ids = @update_item_states.keys

        info log_format("updating item states", item_ids.to_s)

        item_ids.each { |item_id|
          next unless @update_item_states.delete(item_id)

          item = @items[item_id] || next
          next unless item.installed

          update_item_state(item)
        }

        # Sleep for 10 msec in order to poll up more potential changes
        # to the same items.
        sleep(0.01)
      end
    end

  end

  #
  # Update property states:
  #

  module UpdatePropertyStates
    # subscribe_event FOO_UPDATE_PROPERTY_STATES, :update_property_states

    def initialize(*args, &block)
      super
      @update_property_states = {}
    end

    private

    # Requires queue 'property_type'.
    def update_property_state(property_type, property_id)
      # Must be implemented by manager
      raise NotImplementedError
    end

    # Returns FOO_UPDATE_PROPERTY_STATES.
    def update_property_states_event
      # Must be implemented by manager
      raise NotImplementedError
    end

    def add_property_id_to_update_queue(property_type, property_id)
      raise ArgumentError, 'property id of nil not allowed' if property_id.nil?

      update_states = (@update_property_states[property_type] ||= {})

      should_publish = update_states.empty?
      update_states[property_id] = true

      should_publish &&
        publish(update_property_states_event, id: property_type)
    end

    def add_property_ids_to_update_queue(property_type, property_ids)
      raise ArgumentError, 'property id of nil not allowed' if property_ids.index(nil)

      update_states = (@update_property_states[property_type] ||= {})

      should_publish = update_states.empty?

      property_ids.select { |property_id|
        update_states[property_id].nil?
      }.each { |property_id|
        update_states[property_id] = true
      }

      should_publish &&
        publish(update_property_states_event, id: property_type)
    end

    # FOO_UPDATE_PROPERTY_STATES on queue 'property_type'.
    def update_property_states(params)
      property_type = params[:id] || return
      update_states = (@update_property_states[property_type] || return)

      while !update_states.empty?
        property_ids = update_states.keys

        info log_format("updating '#{property_type}' property states", property_ids.to_s)

        property_ids.each { |property_id|
          next unless update_states.delete(property_id)

          update_property_state(property_type, property_id)
        }

        # Sleep for 10 msec in order to poll up more potential changes
        # to the same propertys.
        sleep(0.01)
      end
    end

  end

  # Look up params passed using events and such. Since these generate
  # warning on invalid input they should be used only when the input
  # is assumed to always be correct.
  #
  # A missing value is not an error if 'required != true', while an
  # invalid value for the type requested is.

  # TODO: Move to separate file.

  class ParamError < ArgumentError
    # TODO: Separate msg from message, params and key.
  end

  module LookupParams

    # TODO: Use the backtrace to get the root calling get_param_*
    # method name, and the root Manager method name.

    def throw_param_error(message, params, key)
      # TODO: Improve the exception content.
      raise Vnet::ParamError.new("#{message} (key:#{key} params:#{params}")
    end

    # Specialized method to properly log errors in manager.
    def handle_param_error(param_error)
      # TODO: Check if ParamError and if called from a manager.
      warn log_format(param_error.to_s)
    end

    def get_param(params, key, required = true)
      param = (params && params[key])

      if param.nil? && required
        return throw_param_error('key is missing or nil', params, key)
      end

      # TODO: Add proper FixNum (or other valid integer) type check.

      param
    end

    # MySQL keys are 31 bits, and we use that size of the default id.
    def get_param_id(params, key = :id, required = true)
      param = get_param(params, key, required) || return

      if !(param > 0 && param < (1 << 30))
        return throw_param_error('invalid value for id type', params, key)
      end

      param
    end

    def get_param_id_32(params, key = :id, required = true)
      param = get_param(params, key, required) || return

      if !(param > 0 && param < (1 << 31))
        return throw_param_error('invalid value for id_32 type', params, key)
      end

      param
    end

    # TODO: Add a 32 bit version.
    def get_param_packed_id(params, key = :id, required = true)
      # TODO: Implement get_param_list.
      param_id_list = get_param(params, key, required) || return
      param_id = param_id_list[1]

      if param_id.nil?
        return throw_param_error('list is missing packed id', params, key)
      end

      if !(param_id > 0 && param_id < (1 << 30))
        return throw_param_error('invalid value for packed id type', params, key)
      end

      param_id
    end

    # TODO: Add support for other integer types.
    def get_param_int(params, key, required = true)
      param = get_param(params, key, required) || return

      if !param.is_a?(Fixnum)
        return throw_param_error('value is not an integer type', params, key)
      end

      param
    end

    def get_param_string(params, key, required = true)
      param = get_param(params, key, required) || return

      if !param.is_a?(String)
        return throw_param_error('value is not a string type', params, key)
      end

      if param.empty?
        return throw_param_error('string is empty', params, key)
      end

      param
    end

    def get_param_string_n(params, key, required = true)
      param = get_param(params, key, required) || return

      if !param.is_a?(String)
        return throw_param_error('value is not a string type', params, key)
      end

      param
    end

    # TODO: Add methods to validate IPv4 addresses with different restrictions.
    #
    # TODO: Shouldn't this be creating IPAddr types?
    def get_param_ipv4_address(params, key, required = true)
      param = get_param(params, key, required) || return

      if !IPAddr.new(param, Socket::AF_INET).ipv4?
        return throw_param_error('value is not a valid IPv4 address', params, key)
      end

      param
    end

    def get_param_tp_port(params, key, required = true)
      param = get_param_int(params, key, required) || return

      if !(param > 0 && param < (1 << 15))
        return throw_param_error('value is not a valid transport port', params, key)
      end

      param
    end

    def get_param_of_port(params, key, required = true)
      param = get_param_int(params, key, required) || return

      if !(param > 0 && param < (1 << 31))
        return throw_param_error('value is not a valid OpenFlow port', params, key)
      end

      param
    end

  end
end
