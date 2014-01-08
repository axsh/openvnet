# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class IpLease < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpLease)
      object.interface_uuid ||= object.interface.uuid
      object.mac_lease_uuid ||= object.mac_lease.uuid
      object.network_uuid = object.ip_address.network.uuid
      object.ipv4_address = object.ipv4_address_s
      object.to_hash
    end
  end

  class IpLeaseCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        IpLease.generate(i)
      }
    end
  end
end
