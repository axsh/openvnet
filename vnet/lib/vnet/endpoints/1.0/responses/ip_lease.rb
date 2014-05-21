# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class IpLease < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpLease)
      object.interface_uuid ||= object.interface.uuid if object.interface
      object.mac_lease_uuid ||= object.mac_lease.uuid if object.mac_lease

      network = object.ip_address.network
      object.network_uuid =  network && network.uuid

      object.ipv4_address = object.ipv4_address_s
      object.to_hash
    end
  end

  class IpLeaseCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        IpLease.generate(i)
      }
    end
  end
end
