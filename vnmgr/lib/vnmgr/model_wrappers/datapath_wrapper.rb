# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class DatapathWrapper < Base
    backend_namespace = "datapaths"

    def to_hash
      {
        :uuid => self.uuid,
        :name => self.name,
        :openflow_controller_id => self.openflow_controller_id,
        :ipv4_address => self.ipv4_address,
        :is_connected => self.is_connected,
        :datapath_id => self.datapath_id,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
