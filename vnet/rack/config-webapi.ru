# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'vnet'
require 'rack/cors'
require 'dcell'

Vnet::Initializers::Logger.run("webapi.log")

conf = Vnet::Configurations::Webapi.conf

Vnet::NodeApi.set_proxy(conf.node_api_proxy)

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

case conf.node_api_proxy
when :rpc
  # do nothing
when :direct
  Vnet::Initializers::DB.run(conf.db_uri)
end

params = {
  :id => conf.node.id,
  :addr => conf.node.addr_string,
  :registry => {
    :adapter => conf.registry.adapter,
    :host => conf.registry.host,
    :port => conf.registry.port
  }
}

params[:public] = conf.node.pub_addr_string if conf.node.addr.public != ""

DCell.start(params)

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
