# -*- coding: utf-8 -*-
require 'logger'

module Vnet
  module NodeApi
    class << self
      attr_accessor :raise_on_error
      attr_accessor :logger
      attr_accessor :proxy
    end

    module_function

    def set_proxy(name)
      self.proxy =
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

require_relative("node_api/proxies")

Vnet::NodeApi.raise_on_error = true
Vnet::NodeApi.logger = ::Logger.new(STDERR).tap { |l| l.level = ::Logger::INFO }
Vnet::NodeApi.set_proxy(:direct)
