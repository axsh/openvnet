# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class Base
    SBE = Vnmgr::StorageBackend.backend_class
    class < self
      def backend_namespace(namespace = nil)
        # Sets namespace when argument given
        # Returns namespace otherwise
      end

      def all
        SBE.send(self.backend_namespace).all
      end
    end
    def initialize
      @storage_backend = SBE.new
    end
  end
end
