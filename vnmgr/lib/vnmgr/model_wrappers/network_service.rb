# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class NetworkService < Base
    def to_hash
      {
        :uuid => self.uuid,
        :vif_uuid => self.vif_uuid,
        :display_name => self.display_name,
        :incoming_port => self.incoming_port,
        :outgoing_port => self.outgoing_port,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
