# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class TunnelingProtocol < Base
    def to_hash
      {
        :uuid => self.uuid,
        :src_dc_segment_id => self.src_dc_segment_id,
        :dst_dc_segment_id => self.dst_dc_segment_id,
        :protocol => self.protocol,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
