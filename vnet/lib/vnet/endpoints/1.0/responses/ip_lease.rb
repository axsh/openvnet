# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class IpLease < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpLease)
      # TODO dirty hack
      object.batch.interface.commit(fill: :network).tap do |interface|
        object.vif_uuid = interface.uuid
        object.interface_id = nil
        object.network_uuid = interface.network.uuid if interface.network
      end
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
