# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'vnmgr'
require 'rack/cors'

conf_path = '/etc/wakame-vnet/vnmgr.conf'
raise "Unable to find conf file: #{conf_path}" unless File.exists?(conf_path)

conf = Vnmgr::Configurations::Vnmgr.load(conf_path)
Vnmgr::Initializers::DB.run(conf.db_uri)

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

  run Vnmgr::Endpoints::VNetAPI.new
end
