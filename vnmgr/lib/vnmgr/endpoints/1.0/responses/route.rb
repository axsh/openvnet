# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class Route < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::Route)
      object.to_hash
    end
  end

  class RouteCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Route.generate(i)
      }
    end
  end
end
