# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class DatapathNetwork < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::DatapathNetwork)
      network_uuid = Vnet::ModelWrappers::Network.find(:id => object.network_id).uuid
      {
        :network_uuid => network_uuid,
        :mac_address => object.mac_address
      }
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
