# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class IpLease < Base
    def to_hash
      network = self.batch.network.commit
      vif = self.batch.vif.commit
      ip_address = self.batch.ip_address.commit
      {
        :uuid => self.uuid,
        :network_uuid => network && network.uuid,
        :vif_uuid => vif && vif.uuid,
        :ip_address_uuid => ip_address && ip_address.uuid,
        :alloc_type => self.alloc_type,
        :created_at => self.created_at,
        :updated_at => self.updated_at,
        :deleted_at => self.deleted_at,
        :is_deleted => self.is_deleted
      }
    end
  end
end
