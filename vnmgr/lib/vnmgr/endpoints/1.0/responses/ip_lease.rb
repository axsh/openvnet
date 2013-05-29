# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class IpLease < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::IpLease)
      object.to_hash
    end
  end

  class IpLeaseCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        IpLease.generate(i)
      }
    end
  end
end
