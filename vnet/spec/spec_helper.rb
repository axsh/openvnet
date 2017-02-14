# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'

Bundler.setup(:default)
#Bundler.require(:default, :test)
Bundler.require(:test)

require 'dcell'
require 'trema' # Needed for the to_trema_hash methods in mock_datapath
require 'vnet'

Dir['./spec/helpers/*.rb'].map {|f| require f }
Dir['./spec/support/*.rb'].map {|f| require f }

require "rack"
require "rack/test"
require "fabrication"
require "database_cleaner"

require 'webmock/rspec'

require 'coveralls'

Coveralls.wear!

DCell.setup

# When a datapath is initialized, it'll have flow.
# The one that accepts ARP in the INTERFACE_INGRESS_FILTER table
DATAPATH_IDLE_FLOWCOUNT = 1

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  Vnet::Configurations::Common.paths = ["#{File.dirname(File.expand_path(__FILE__))}/config"]

  logfile = File.open(File.expand_path("../log/spec.log", __FILE__), 'a')
  logfile.sync = true
  Celluloid.logger = Logger.new(logfile)
  #Celluloid.logger = nil
  Celluloid.shutdown_timeout = 1

  vnmgr_conf = Vnet::Configurations::Vnmgr.load
  webapi_conf = Vnet::Configurations::Webapi.load

  Vnet::NodeApi.set_proxy(webapi_conf.node_api_proxy)
  Vnet::Initializers::DB.run(webapi_conf.db_uri)
  #Vnet::Initializers::DB.run(vnmgr_conf.db_uri, :debug_sql => true)

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
    Fabrication.clear_definitions
    Celluloid.shutdown
    Celluloid.boot
  end

  config.after(:each) do
    Celluloid.shutdown
    DatabaseCleaner.clean
  end
end
