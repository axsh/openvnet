# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class IpLeaseWrapper < Base
    backend_namespace = "ip_leases"

    def to_hash
      {
        :uuid => self.uuid,
        :network_id => self.network_id,
        :vif_id => self.vif_id,
        :ip_handle_id => self.ip_handle_id,
        :alloc_type => self.alloc_type,
        :created_at => self.created_at,
        :updated_at => self.updated_at,
        :deleted_at => self.deleted_at,
        :is_deleted => self.is_deleted
      }
    end
  end
end
