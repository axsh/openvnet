# -*- coding: utf-8 -*-

require 'dcell'

module Vnmgr::StorageBackends
  class DBA < StorageBackend
    def initialize(conf)
      DCell.start :id => conf.cluster_name, :addr => "tcp://#{conf.vnmgr_agent_ip}:#{conf.vnmgr_agent_port}",
      :registry => {
        :adapter => 'redis',
        :host => conf.redis_host,
        :port => conf.redis_port
      }
    end

    Vnmgr::Constants::StorageBackends::DBA::MODEL_METHODS.each { |method_name,model_name|
      klass = Class.new(DBA) do
        define_method :all {
          dba_node = DCell::Node["vnmgr"]
          networks = dba_node[:db_agent].get_all(model_name)
        }
      end
      const_set(model_name,klass)
      define_method method_name { const_get(model_name) }
    }

  end
end

