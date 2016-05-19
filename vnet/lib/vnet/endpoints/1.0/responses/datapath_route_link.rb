# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class DatapathRouteLink < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::DatapathRouteLink)
      object.to_hash
    end
  end

  class DatapathRouteLinkCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        DatapathRouteLink.generate(i)
      }
    end
  end
end
