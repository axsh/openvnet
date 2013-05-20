# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class RouterWrapper < Base
    backend_namespace = "routers"

    def to_hash
      {
        :uuid => self.uuid,
        :network_id => self.network_id,
        :ipv4_address => self.ipv4_address,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
