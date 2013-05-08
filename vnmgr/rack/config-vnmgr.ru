# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'vnmgr'
require 'rack/cors'
require 'dcell'

conf_path = '/etc/wakame-vnet/vnmgr.conf'
raise "Unable to find conf file: '#{conf_path}'" unless File.exists?(conf_path)
Vnmgr::Endpoints::V10::VNetAPI.load_conf(conf_path)

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
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
