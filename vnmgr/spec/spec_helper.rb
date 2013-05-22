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

  config.before(:suite) do
    vnmgr_conf = Vnmgr::Endpoints::V10::VNetAPI.load_conf(File.expand_path("../config/vnmgr.conf", __FILE__))
    dba_conf = Vnmgr::Configurations::Dba.load(File.expand_path("../config/dba.conf", __FILE__)).config
    Vnmgr::Initializers::DB.run(dba_conf[:db_uri])

    DCell.start :id => dba_conf[:cluster_name], :addr => "tcp://#{dba_conf[:db_agent_ip]}:#{dba_conf[:db_agent_port]}",
    :registry => {
      :adapter => 'redis',
      :host => dba_conf[:redis_host],
      :port => dba_conf[:redis_port]
    }

    [:network, :vif, :dhcp_range, :mac_range, :router, :tunnel, :dc_network, :datapath, :open_flow_controller, :ip_address, :ip_lease].each do |s|
      klass = s.to_s.split('_').map {|w| w.capitalize }.join('')
      Module.const_get('Vnmgr').const_get('NodeModules').const_get('DBA').const_get(klass).supervise_as s
    end

    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
