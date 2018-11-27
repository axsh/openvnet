# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'vnet'
require 'rack/cors'
require 'celluloid/autostart'
require 'dcell'
require 'dcell/registries/redis_adapter'

Vnet::Initializers::Logger.run("webapi.log")
Vnet::NodeApi.set_proxy(Vnet::Configurations::Webapi.conf.node_api_proxy)

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

case Vnet::Configurations::Webapi.conf.node_api_proxy
when :rpc
  # do nothing
when :direct
  Vnet::Initializers::DB.run(Vnet::Configurations::Webapi.conf.db_uri)
end

DCell.start(Vnet::Configurations::Webapi.dcell_params)

map '/api' do
  use Rack::Cors do
    allow do
      origins '*'
      resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
    end
  end

  map '/1.0' do
    run Vnet::Endpoints::V10::VnetAPI.new
  end

  # for compatibirity
  run Vnet::Endpoints::V10::VnetAPI.new
end
