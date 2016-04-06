# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class TranslationStaticAddress < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::TranslationStaticAddress)
      object.to_hash.tap { |res|
        res[:ingress_ipv4_address] = object.batch.ingress_ipv4_address_s.commit
        res[:egress_ipv4_address] = object.batch.egress_ipv4_address_s.commit

        route_link = object.batch.route_link.commit
        res[:route_link_uuid] = route_link.uuid if route_link

        res[:ingress_network_uuid] = object.batch.ingress_network.canonical_uuid.commit if object.ingress_network_id
        res[:egress_network_uuid] = object.batch.egress_network.canonical_uuid.commit if object.egress_network_id
      }
    end
  end

  class TranslationStaticAddressCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        TranslationStaticAddress.generate(i)
      }
    end
  end
end
