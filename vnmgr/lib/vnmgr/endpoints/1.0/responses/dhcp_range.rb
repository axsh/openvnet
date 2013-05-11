# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class DhcpRange < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::DhcpRangeWrapper)
      object.to_hash
    end
  end

  class DhcpRangeCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        DhcpRange.generate(i)
      }
    end
  end
end
