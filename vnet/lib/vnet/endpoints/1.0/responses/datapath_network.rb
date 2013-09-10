# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class DatapathNetwork < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::DatapathNetwork)
      network_uuid = Vnet::ModelWrappers::Network.find(:id => object.network_id).uuid
      {
        :network_uuid => network_uuid,
        :broadcast_mac_address => object.broadcast_mac_address
      }
    end
  end

  class DatapathNetworkCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        DatapathNetwork.generate(i)
      }
    end
  end
end
