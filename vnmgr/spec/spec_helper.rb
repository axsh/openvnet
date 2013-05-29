# -*- coding: utf-8 -*-
require 'rspec'
require 'bundler'
Bundler.require(:default, :test)
require 'vnmgr'
Dir['./spec/support/*.rb'].map {|f| require f }
require 'rack/test'
require 'coveralls'
Coveralls.wear!

set :environment, :test

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config_dir = "#{File.dirname(File.expand_path(__FILE__))}/config"
  vnmgr_conf = Vnmgr::Endpoints::V10::VNetAPI.load_conf("#{config_dir}/common.conf", "#{config_dir}/vnmgr.conf")
  dba_conf = Vnmgr::Configurations::Dba.load("#{config_dir}/common.conf", "#{config_dir}/dba.conf")
  Vnmgr::Initializers::DB.run(vnmgr_conf.db_uri)

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
