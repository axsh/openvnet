# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Interface < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Interface)
      hash = object.to_hash.merge({
        network_uuid: object[:network] ? object[:network][:uuid] : nil,
        ipv4_address: object[:ipv4_address],
        mac_address: object[:mac_address],
        owner_datapath_uuid: object[:owner_datapath] ? object[:owner_datapath][:uuid] : nil,
      })
    end
  end

  class InterfaceCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Interface.generate(i)
      }
    end
  end


end
