# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class VifWrapper < Base

    def to_hash
      {
        :uuid => self.uuid,
        :network_id => self.network_id,
        :mac_addr => self.mac_addr,
        :state => self.state,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
