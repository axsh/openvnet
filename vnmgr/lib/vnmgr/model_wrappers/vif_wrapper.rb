# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class VifWrapper < Base
    backend_namespace = "vifs"

    def to_hash
      {
        :uuid => self.uuid,
        :network_id => self.network_id,
        :mac_addr => self.mac_addr,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
