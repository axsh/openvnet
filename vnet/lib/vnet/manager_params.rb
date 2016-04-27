# -*- coding: utf-8 -*-

# Lookup methods for params passed using events and item_map. Since
# these generate special exceptions on invalid input they should only
# be used when the input is assumed to always be correct.
#
# This is not intended for user input validation.
#
# A missing value is not an error if 'required != true', while an
# invalid value for the type requested is.
#
# Usage:
#
# begin
#   port_number = get_param_of_port(params, :port_number)
# rescue Vnet::ParamError => e
#   handle_param_error(e)
# end

module Vnet

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

      if !(param > 0 && param < (1 << 31))
        return throw_param_error('invalid value for id type', params, key)
      end

      param
    end

    def get_param_id_32(params, key = :id, required = true)
      param = get_param(params, key, required) || return

      if !(param > 0 && param < (1 << 32))
        return throw_param_error('invalid value for id_32 type', params, key)
      end

      param
    end

    def get_param_packed_id(params, key = :id, required = true, id_size = 31)
      # TODO: Implement get_param_list.
      param_id_list = get_param(params, key, required) || return
      param_id = param_id_list[1]

      if param_id.nil?
        return throw_param_error('list is missing packed id', params, key)
      end

      if !(param_id > 0 && param_id < (1 << id_size))
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

    def get_param_symbol(params, key, required = true)
      param = get_param(params, key, required) || return

      if !param.is_a?(Symbol)
        return throw_param_error('value is not a symbol type', params, key)
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

      if !(param > 0 && param < (1 << 16))
        return throw_param_error('value is not a valid transport port', params, key)
      end

      param
    end

    def get_param_of_port(params, key, required = true)
      param = get_param_int(params, key, required) || return

      if !(param > 0 && param < (1 << 32))
        return throw_param_error('value is not a valid OpenFlow port', params, key)
      end

      param
    end

  end
end
