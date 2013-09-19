# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Interface < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Interface)
      object.to_hash
    end
  end

  class InterfaceCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Interface.generate(i)
      }
    end
  end


end
