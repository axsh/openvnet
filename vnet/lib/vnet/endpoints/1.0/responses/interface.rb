# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Interface < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Interface)
      if object.ip_leases.first
        object.network_uuid = object.ip_leases.first.ip_address.network.uuid
        object.ipv4_address = object.ip_leases.first.ip_address.ipv4_address_s
      end
      if object.mac_leases.first
        object.mac_address = object.mac_leases.first.mac_address_s
      end
      object.owner_datapath_uuid = object.owner_datapath.uuid if object.owner_datapath
      object.to_hash
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
