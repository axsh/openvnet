# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class MacLease < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::MacLeaseWrapper)
      object.to_hash
    end
  end

  class MacLeaseCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        MacLease.generate(i)
      }
    end
  end
end
