# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class IpLease < Base
    def to_hash
      {
        :uuid => self.uuid,
        :network_id => self.network_id,
        :interface_id => self.interface_id,
        :ip_address_id => self.ip_address_id,
        :created_at => self.created_at,
        :updated_at => self.updated_at,
        :deleted_at => self.deleted_at,
        :is_deleted => self.is_deleted
      }
    end
  end
end
