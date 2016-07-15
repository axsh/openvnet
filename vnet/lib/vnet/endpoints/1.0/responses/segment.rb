# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Segment < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::Segment)
      object.to_hash
    end
  end

  class SegmentCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| Segment.generate(i) }
    end
  end
end
