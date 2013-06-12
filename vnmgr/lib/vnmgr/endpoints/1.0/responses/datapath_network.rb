# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class DatapathNetwork < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::DatapathNetwork)
      object.to_hash
    end
  end

  class DatapathNetworkCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        DatapathNetwork.generate(i)
      }
    end
  end
end
