# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class IpRangeRange < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::IpRangeRange)
      object.to_hash
    end
  end

  class IpRangeRangeCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| IpRangeRange.generate(i) }
    end
  end
end
