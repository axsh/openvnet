# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class MacLeaseWrapper < Base
    backend_namespace = "mac_leases"

    def to_hash
      {
        :uuid => self.uuid,
        :mac_addr => self.mac_addr,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
