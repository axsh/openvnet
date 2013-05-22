# -*- coding: utf-8 -*-

module Vnmgr
  class StorageBackend
    #TODO: Write interface here
  end

  module StorageBackends
    def self.backend_class(vnmgr_conf, dba_conf, common_conf)
      case vnmgr_conf.storage_backend
      when "dba"
        DBA.new(vnmgr_conf, dba_conf, common_conf)
      when "direct"
        raise NotImplementedError
      else
        raise "Unknown storage backend: #{vnmgr_conf.storage_backend}"
      end
    end
  end
end
