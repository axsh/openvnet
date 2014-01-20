# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class NetworkService < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::NetworkService)
      object[:interface_uuid] = object.interface.uuid if object.interface
      object.to_hash
    end
  end

  class NetworkServiceCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        NetworkService.generate(i)
      }
    end
  end
end
