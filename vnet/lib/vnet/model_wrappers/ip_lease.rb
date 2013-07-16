# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class IpLease < Base
    def to_hash
      {
        :uuid => self.uuid,
        :network_uuid => self.network_uuid,
        :vif_uuid => self.vif_uuid,
        :ip_handle_uuid => self.ip_address_uuid,
        :alloc_type => self.alloc_type,
        :created_at => self.created_at,
        :updated_at => self.updated_at,
        :deleted_at => self.deleted_at,
        :is_deleted => self.is_deleted
      }
    end
  end
end
