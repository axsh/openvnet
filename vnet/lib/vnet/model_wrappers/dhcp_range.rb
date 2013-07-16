# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class DhcpRange < Base
    def to_hash
      {
        :uuid => self.uuid,
        :network_uuid => self.network_uuid,
        :range_begin => self.range_begin,
        :range_end => self.range_end,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
