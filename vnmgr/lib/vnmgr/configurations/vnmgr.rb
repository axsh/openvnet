
# -*- coding: utf-8 -*-

module Vnmgr::Configurations
  class Vnmgr < Common
    param :node_name, :default => "vnmgr"
    param :dba_node_name, :default => "dba"
    param :dba_actor_name, :default => "dba"
    param :ip
    param :port
    param :data_access_proxy, :default => :direct
  end
end
