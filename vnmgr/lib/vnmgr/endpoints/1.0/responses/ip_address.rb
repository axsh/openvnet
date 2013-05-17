# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class IpAddress < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::IpAddressWrapper)
      object.to_hash
    end
  end

  class IpAddressCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        IpAddress.generate(i)
      }
    end
  end
end
