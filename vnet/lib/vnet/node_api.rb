# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    @@options = {
      raise_on_error: true,
      logger: ::Logger.new(STDOUT)
    }

    module_function

    def raise_on_error=(raise_on_error)
      @@options[:raise_on_error] = !! raise_on_error
    end

    def logger=(logger)
      @@options[:logger] = logger
    end

    def get_proxy(name)
      case name.to_sym
      when :rpc
        RpcProxy.new(@@options)
      when :direct
        DirectProxy.new(@@options)
      else
        raise "Unknown proxy: #{name}"
      end
    end
  end
end
