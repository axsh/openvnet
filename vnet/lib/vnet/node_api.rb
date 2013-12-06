# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    class << self
      attr_accessor :raise_on_error
      attr_accessor :logger
    end

    module_function

    def get_proxy(name)
      case name.to_sym
      when :rpc
        RpcProxy.new
      when :direct
        DirectProxy.new
      else
        raise "Unknown proxy: #{name}"
      end
    end
  end
end

Vnet::NodeApi.raise_on_error = true
Vnet::NodeApi.logger = Logger.new(STDERR).tap { |l| l.level = Logger::INFO }
