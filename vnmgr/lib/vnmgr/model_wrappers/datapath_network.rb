# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class DatapathNetwork < Base
    def to_hash
      {
        :uuid => self.uuid,
        :datapath_id => self.datapath_id,
        :network_id => self.network_id,
        :broadcast_mac_addr => self.broadcast_mac_addr,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
