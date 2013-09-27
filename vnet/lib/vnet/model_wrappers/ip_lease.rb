# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class IpLease < Base
    include Helpers::IPv4
    def to_hash
      network = self.batch.network.commit
      interface = self.batch.interface.commit
      {
        :uuid => self.uuid,
        :network_uuid => network && network.uuid,
        :interface_uuid => interface && interface.uuid,
        :ip_address_uuid => ip_address && ip_address.uuid,
        :ipv4_address => self.ipv4_address_s,
        :created_at => self.created_at,
        :updated_at => self.updated_at,
        :deleted_at => self.deleted_at,
        :is_deleted => self.is_deleted
      }
    end
  end
end
