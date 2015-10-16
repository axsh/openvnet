# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Topology < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::Topology)
      object.to_hash
    end
  end

  class TopologyCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| Topology.generate(i) }
    end
  end
end
