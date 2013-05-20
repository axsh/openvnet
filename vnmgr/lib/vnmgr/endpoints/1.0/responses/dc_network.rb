# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class DcNetwork < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::DcNetworkWrapper)
      object.to_hash
    end
  end

  class DcNetworkCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        DcNetwork.generate(i)
      }
    end
  end
end
