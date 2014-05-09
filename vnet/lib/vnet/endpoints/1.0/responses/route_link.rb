# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class RouteLink < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::RouteLink)
      object.to_hash.merge({ mac_address: object.mac_address_s })
    end
  end

  class RouteLinkCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        RouteLink.generate(i)
      }
    end
  end
end
