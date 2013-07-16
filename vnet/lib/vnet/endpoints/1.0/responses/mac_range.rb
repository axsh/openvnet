# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class MacRange < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::MacRange)
      object.to_hash
    end
  end

  class MacRangeCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        MacRange.generate(i)
      }
    end
  end
end
