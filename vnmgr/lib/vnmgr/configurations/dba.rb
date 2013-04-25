module Vnmgr
  module Configurations
    class Dba < Fuguta::Configuration
      param :redis_host, :default => '127.0.0.1'
      param :redis_port, :default => 6374
      param :db_agent_ip, :default => '127.0.0.1'
      param :db_agent_port, :default => '9001'
      param :cluster_name, :default => 'vnmgr'
      param :node_name, :default => 'db_agent'
    end
  end
end
