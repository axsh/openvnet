# -*- coding: utf-8 -*-

module Vnmgr
  module Configurations
    class Dba < Fuguta::Configuration
      param :cluster_name
      param :node_name
      param :ip
      param :port
      param :db_uri
      param :db_tables
    end
  end
end
