# -*- coding: utf-8 -*-
require 'rubygems'
require 'bundler'
Bundler.setup(:default)
#Bundler.require(:default, :test)
Bundler.require(:test)
require 'dcell'
require 'vnet'

Dir['./spec/support/*.rb'].map {|f| require f }

require "rack"
require "rack/test"
require "fabrication"
require "database_cleaner"

require 'coveralls'
Coveralls.wear!

DCell.setup

# When a datapath is initialized, it'll have two flows. One to allow ARP in
# TABLE_INTERFACE_INGRESS_FILTER and another one to allow all traffic by default
# in TABLE_INTERFACE_EGRESS_FILTER
DATAPATH_IDLE_FLOWCOUNT = 2

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  Vnet::Configurations::Common.paths = ["#{File.dirname(File.expand_path(__FILE__))}/config"]

  #Celluloid.logger = ::Logger.new("test.log")
  Celluloid.logger = nil

  vnmgr_conf = Vnet::Configurations::Vnmgr.load
  webapi_conf = Vnet::Configurations::Webapi.load

  Vnet::ModelWrappers::Base.set_proxy(webapi_conf.node_api_proxy)
  Vnet::Initializers::DB.run(webapi_conf.db_uri)
  #Vnet::Initializers::DB.run(vnmgr_conf.db_uri, :debug_sql => true)

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
    Fabrication.clear_definitions
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
