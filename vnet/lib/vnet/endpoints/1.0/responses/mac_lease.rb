# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class MacLease < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::MacLease)
      object.interface_uuid ||= object.interface.uuid
      object.mac_address = object.mac_address_s
      object.to_hash
    end
  end

  class MacLeaseCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        MacLease.generate(i)
      }
    end
  end
end
