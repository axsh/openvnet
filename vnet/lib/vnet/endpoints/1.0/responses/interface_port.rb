# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class InterfacePort < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::InterfacePort)
      object.to_hash
    end
  end

  class InterfacePortCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        InterfacePort.generate(i)
      }
    end
  end
end
