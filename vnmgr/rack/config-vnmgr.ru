# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'vnmgr'
require 'rack/cors'
require 'dcell'

conf = Vnmgr::Configurations::Vnmgr.conf
Vnmgr::ModelWrappers::Base.set_proxy(conf)

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

case conf.data_access_proxy
when :dba
  DCell.start(:id => conf.node.id, :addr => conf.node.addr_string,
    :registry => {
      :adapter => conf.registry.adapter,
      :host => conf.registry.host,
      :port => conf.registry.port })
when :direct
  Vnmgr::Initializers::DB.run(conf.db_uri)
end

map '/api' do
  use Rack::Cors do
    allow do
      origins '*'
      resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
    end
  end

  run Vnmgr::Endpoints::V10::VNetAPI.new
end
