# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Route < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Route)
      object.to_hash
    end
  end

  class RouteCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Route.generate(i)
      }
    end
  end
end
