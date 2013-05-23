# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'vnmgr'
require 'rack/cors'
require 'dcell'

vnmgr_conf_path = '/etc/wakame-vnet/vnmgr.conf'
dba_conf_path = '/etc/wakame-vnet/dba.conf'
common_conf_path = '/etc/wakame-vnet/common.conf'
[vnmgr_conf_path, dba_conf_path, common_conf_path].each do |path|
  raise "Unable to find conf file: '#{path}'" unless File.exists?(path)
end
Vnmgr::Endpoints::V10::VNetAPI.load_conf(vnmgr_conf_path, dba_conf_path, common_conf_path)

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
