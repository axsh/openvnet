# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class IpLease < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpLease)

      object.interface_uuid ||= object.batch.interface.canonical_uuid.commit if object.interface_id
      object.mac_lease_uuid ||= object.batch.mac_lease.canonical_uuid.commit if object.mac_lease_id

      object.network_uuid ||= object.batch.network.canonical_uuid.commit

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
