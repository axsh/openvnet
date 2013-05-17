# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class MacRange < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::MacRangeWrapper)
      object.to_hash
    end
  end

  class MacRangeCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        MacRange.generate(i)
      }
    end
  end
end
