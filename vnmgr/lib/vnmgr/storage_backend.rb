# -*- coding: utf-8 -*-

module Vnmgr
  StorageModels = [:network,:vif]
  class StorageBackend
    # p StorageModels
    # StorageModels.each { |model|
    #   define_method model { raise NotImplementedError, model }
    # }
  end

  module StorageBackends
    def self.backend_class(conf)
      case conf.storage_backend
      when "dba"
        DCell.me || DCell.start(:id => conf.cluster_name, :addr => "tcp://#{conf.vnmgr_agent_ip}:#{conf.vnmgr_agent_port}",
        :registry => {
          :adapter => 'redis',
          :host => conf.redis_host,
          :port => conf.redis_port
        })

        DBA.new(conf)
      when "direct"
        raise NotImplementedError
      else
        raise "Unknown storage backend: #{conf.storage_backend}"
      end
    end
  end
end
