# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Iface < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Iface)
      object.to_hash
    end
  end

  class IfaceCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Iface.generate(i)
      }
    end
  end


end
