# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class VlanTranslation < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::VlanTranslation)
      network = Vnet::ModelWrappers::Network.find(:id => object.network_id)
      object.to_hash.tap { |h|
        translation = object.batch.translation.commit
        h[:translation_uuid] = translation.uuid if translation
        h[:mac_address] = object.mac_address_s
        h[:network_uuid] = network && network.uuid
      }
    end
  end

  class VlanTranslationCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        VlanTranslation.generate(i)
      }
    end
  end
end
