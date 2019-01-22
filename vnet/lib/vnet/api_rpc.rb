# -*- coding: utf-8 -*-

require 'vnet'

module Vnet

  if use_api_proxy
    raise "Could not load 'vnet/api_rpc', api proxy already loaded."
  end

  use_api_proxy = :rpc

  module NodeApi
    autoload :RpcProxy, 'vnet/node_api/rpc_proxy'
  end

  Vnet::NodeApi.set_api_proxy(Vnet::NodeApi::RpcProxy.new)

end
