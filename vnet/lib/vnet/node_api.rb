# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    def self.get_proxy(conf)
      case conf.node_api_proxy
      when :rpc
        RpcProxy.new(conf)
      when :direct
        DirectProxy.new(conf)
      else
        raise "Unknown proxy: #{conf.node_api_proxy}"
      end
    end
  end
end
