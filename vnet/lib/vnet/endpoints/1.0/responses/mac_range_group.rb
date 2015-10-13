# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class MacRangeGroup < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::MacRangeGroup)
      object.to_hash
    end
  end

  class MacRangeGroupCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        MacRangeGroup.generate(i)
      }
    end
  end
end
