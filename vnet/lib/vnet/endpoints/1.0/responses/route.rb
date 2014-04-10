# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Route < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(route)
      argument_type_check(route, Vnet::ModelWrappers::Route)
      res = route.to_hash
      res[:ipv4_network] = route.ipv4_network_s
      res
    end
  end

  class RouteCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| Route.generate(i) }
    end
  end
end
