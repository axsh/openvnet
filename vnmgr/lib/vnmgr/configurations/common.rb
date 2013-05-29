
# -*- coding: utf-8 -*-

module Vnmgr::Configurations
  class Common < Fuguta::Configuration
    param :redis_host, :default => '127.0.0.1'
    param :redis_port, :default => 6379
    param :db_uri
  end
end
