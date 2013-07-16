# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Vif < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Vif)
      object.to_hash
    end
  end

  class VifCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Vif.generate(i)
      }
    end
  end


end
