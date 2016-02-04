# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Translation < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Translation)
      object.to_hash.tap do |res|
        interface = object.batch.interface.commit
        res[:interface_uuid] = interface.uuid if interface
      end
    end

    def self.translation_static_addresses(object)
      argument_type_check(object,Vnet::ModelWrappers::Translation)
      {
        :uuid => object.uuid,
        # :translation_static_addresses => DatapathNetworkCollection.generate(
        #   datapath.batch.datapath_networks.commit
        # )
      }
    end

  end

  class TranslationCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Translation.generate(i)
      }
    end
  end

  class TranslationStatic < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::TranslationStatic)
      object.to_hash.tap { |res|
        res[:ingress_ipv4_address] = object.batch.ingress_ipv4_address_s.commit
        res[:egress_ipv4_address] = object.batch.egress_ipv4_address_s.commit

        route_link = object.batch.route_link.commit
        res[:route_link_uuid] = route_link.uuid if route_link
      }
    end
  end

  class TranslationStaticCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        TranslationStatic.generate(i)
      }
    end
  end

end
