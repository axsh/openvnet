# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class DatapathRouteLink < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::DatapathRouteLink)
      relation = Vnet::ModelWrappers::RouteLink.find(:id => object.route_link_id)
      route_link_uuid = relation.uuid
      {
        :route_link_uuid => route_link_uuid,
        :mac_address => relation.mac_address,
        :is_connected => relation.is_connected
      }
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
