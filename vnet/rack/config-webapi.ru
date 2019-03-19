# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'vnet/api_rpc'
require 'rack/cors'
require 'dcell'

Vnet::Initializers::Logger.run("webapi.log")
Vnet::Configurations::Webapi.conf

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

Celluloid.start
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
