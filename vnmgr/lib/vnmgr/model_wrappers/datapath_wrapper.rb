# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class DatapathWrapper < Base

    def to_hash
      {
        :uuid => self.uuid,
        :open_flow_controller_uuid => self.open_flow_controller_uuid,
        :display_name => self.display_name,
        :ipv4_address => self.ipv4_address,
        :is_connected => self.is_connected,
        :datapath_id => self.datapath_id,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
