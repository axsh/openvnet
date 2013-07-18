# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    def self.get_proxy(name)
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
