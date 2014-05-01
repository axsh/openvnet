# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class IpRangeGroup < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpRangeGroup)
      object.to_hash
    end
  end

  class IpRangeGroupCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        IpRangeGroup.generate(i)
      }
    end
  end
end
