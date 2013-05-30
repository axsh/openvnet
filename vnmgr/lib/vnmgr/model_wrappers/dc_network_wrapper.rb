# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class DcNetworkWrapper < Base

    def to_hash
      {
        :uuid => self.uuid,
        :display_name => self.uuid,
        :parent_id => self.parent_id,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
