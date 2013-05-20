# -*- coding: utf-8 -*-

module Vnmgr
  class StorageBackend
    #TODO: Write interface here
  end

  module StorageBackends
    def self.backend_class(conf)
      case conf.storage_backend
      when "dba"
        DBA.new(conf)
      when "direct"
        raise NotImplementedError
      else
        raise "Unknown storage backend: #{conf.storage_backend}"
      end
    end
  end
end
