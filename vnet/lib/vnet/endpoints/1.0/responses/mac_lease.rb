# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class MacLease < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::MacLease)

      object.to_hash.tap { |res|
        object.batch.interface.commit.tap { |m| res[:interface_uuid] = m && m.uuid }
        object.batch.segment.commit.tap { |m| res[:segment_uuid] = m && m.uuid }
        res[:mac_address] = object.mac_address_s
      }
    end
  end

  class MacLeaseCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i|
        MacLease.generate(i)
      }
    end
  end
end
