# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class IpRangesRange < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::IpRangesRange)
      object.to_hash
    end
  end

  class IpRangesRangeCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| IpRangesRange.generate(i) }
    end
  end
end
