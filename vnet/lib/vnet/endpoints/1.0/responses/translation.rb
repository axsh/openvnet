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
end
