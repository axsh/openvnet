
# -*- coding: utf-8 -*-

module Vnmgr::Configurations
  class Vna < Common
    param :ip
    param :port
    param :node_name, :default => "vnmgr"
    param :dba_node_name, :default => "dba"
    param :dba_actor_name, :default => "dba"
    param :data_access_proxy, :default => :dba
  end
end
