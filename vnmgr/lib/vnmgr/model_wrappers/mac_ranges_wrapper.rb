# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class MacRangeWrapper < Base
    backend_namespace = "mac_ranges"

    def to_hash
      {
        :uuid => self.uuid,
        :vendor_id => self.vendor_id,
        :range_begin => self.range_begin,
        :range_end => self.range_end,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
