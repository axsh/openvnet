# -*- coding: utf-8 -*-

require 'dcell'

module Vnmgr::StorageBackends
  class DBA < Vnmgr::StorageBackend
    def initialize(conf)
      #TODO: Make these configuration keys more generic so they can be used in other places than vnmgr
      DCell.me || DCell.start(:id => conf.cluster_name, :addr => "tcp://#{conf.vnmgr_agent_ip}:#{conf.vnmgr_agent_port}",
      :registry => {
        :adapter => 'redis',
        :host => conf.redis_host,
        :port => conf.redis_port
      })
    end

    def method_missing(method_name,*args)
      result = JSON.parse(DCell::Node["vnmgr"][:db_agent].send(method_name,*args))
      case result
      when Array
        result.map{|r| Vnmgr::ModelWrappers.const_get(r["wrapper_class"]).new(r) }
      when nil
        nil
      else
        Vnmgr::ModelWrappers.const_get(result["wrapper_class"]).new(result)
      end
    end
  end
end

