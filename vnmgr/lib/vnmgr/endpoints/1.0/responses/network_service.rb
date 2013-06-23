# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class NetworkService < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::NetworkService)
      object.to_hash
    end
  end

  class NetworkServiceCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        NetworkService.generate(i)
      }
    end
  end
end
