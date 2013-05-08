# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class Network < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::NetworkWrapper)
      object.to_hash
    end
  end

  class NetworkCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Network.generate(i)
      }
    end
  end


end
