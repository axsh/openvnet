# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class DatapathNetwork < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::DatapathNetwork)
      object.to_hash
    end
  end

  class DatapathNetworkCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        DatapathNetwork.generate(i)
      }
    end
  end
end
