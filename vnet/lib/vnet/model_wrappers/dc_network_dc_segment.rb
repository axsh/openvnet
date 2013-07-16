# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class DcNetworkDcSegment < Base
    def to_hash
      {
        :dc_network_id => self.dc_network_id,
        :dc_segment_id => self.dc_segment_id,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
