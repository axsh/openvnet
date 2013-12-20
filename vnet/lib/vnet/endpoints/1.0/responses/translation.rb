# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Translation < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Translation)
      object.to_hash
    end

    def self.translate_static_addresses(object)
      argument_type_check(object,Vnet::ModelWrappers::Translation)
      {
        :uuid => object.uuid,
        # :translate_static_addresses => DatapathNetworkCollection.generate(
        #   datapath.batch.datapath_networks.commit
        # )
      }
    end

  end

  class TranslationCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Translation.generate(i)
      }
    end
  end
end
