# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class Datapath < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::Datapath)
      object.to_hash
    end
  end

  class DatapathCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Datapath.generate(i)
      }
    end
  end
end
