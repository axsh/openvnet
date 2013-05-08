
# -*- coding: utf-8 -*-

module Vnmgr::Configurations
  class Vnmgr < Fuguta::Configuration
    param :redis_host, :default => '127.0.0.1'
    param :redis_port, :default => 6379
    param :vnmgr_agent_ip, :default => '127.0.0.1'
    param :vnmgr_agent_port, :default => '9002'
    param :cluster_name, :default => 'webapi'
  end
end
