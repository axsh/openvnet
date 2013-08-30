# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class Route < Base

    def to_hash
      {
        :uuid => self.uuid,
        :route_link_uuid => self.batch.route_link.commit.uuid,
        :vif_uuid => self.batch.vif.commit && self.batch.vif.commit.uuid,
        :route_type => self.route_type,
        :ipv4_address => self.ipv4_address,
        :ipv4_prefix => self.ipv4_prefix,
        :ingress => self.ingress,
        :egress => self.egress,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
