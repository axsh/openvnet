# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class Vif < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::Vif)
      object.to_hash
    end
  end

  class VifCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Vif.generate(i)
      }
    end
  end


end
