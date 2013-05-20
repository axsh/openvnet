# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class DhcpRangeWrapper < Base
    backend_namespace = "dhcp_ranges"

    def to_hash
      {
        :uuid => self.uuid,
        :network_id => self.network_id,
        :range_begin => self.range_begin,
        :range_end => self.range_end,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
