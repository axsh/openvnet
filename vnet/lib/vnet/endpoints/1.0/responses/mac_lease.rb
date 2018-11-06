# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class MacLease < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::MacLease)

      object.to_hash.tap { |res|
        object.interface.tap { |m| res[:interface_uuid] = m && m.uuid }
        object.segment.tap { |m| res[:segment_uuid] = m && m.uuid }
        res[:mac_address] = object.mac_address_s

        res[:to_hash] = res.inspect
        res[:object] = object.inspect
        res[:segment] = object.batch.segment.commit.inspect
        res[:_mac_address] = object.batch._mac_address.commit.inspect
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
