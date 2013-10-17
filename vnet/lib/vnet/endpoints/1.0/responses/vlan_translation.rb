# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class VlanTranslation < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::VlanTranslation)
      object.to_hash
    end
  end

  class VlanTranslationCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        VlanTranslation.generate(i)
      }
    end
  end
end
