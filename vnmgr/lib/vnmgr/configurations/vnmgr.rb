
# -*- coding: utf-8 -*-

module Vnmgr::Configurations
  class Vnmgr < Fuguta::Configuration
    param :cluster_name
    param :ip
    param :port
    param :storage_backend, :default => 'dba'
  end
end
