# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class Tunnel < Base
    def to_hash
      {
        :uuid => self.uuid,
        :src_datapath_id => self.src_datapath_id,
        :dst_datapath_id => self.dst_datapath_id,
        :display_name => self.display_name,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
