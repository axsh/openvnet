# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class TunnelWrapper < Base
    backend_namespace = "tunnels"

    def to_hash
      {
        :uuid => self.uuid,
        :src_network_id => self.src_network_id,
        :dst_network_id => self.dst_network_id,
        :tunnel_id => self.tunnel_id,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
