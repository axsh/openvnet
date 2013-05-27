# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class TunnelWrapper < Base
    backend_namespace = "tunnels"

    def to_hash
      {
        :uuid => self.uuid,
        :src_network_uuid => self.src_network_uuid,
        :dst_network_uuid => self.dst_network_uuid,
        :tunnel_id => self.tunnel_id,
        :ttl => self.ttl,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
