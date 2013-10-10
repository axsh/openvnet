# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class Route < Base
    include Helpers::IPv4

    def to_hash
      interface = self.batch.interface.commit
      {
        :uuid => self.uuid,
        :route_link_uuid => self.batch.route_link.commit.uuid,
        :interface_uuid => interface && interface.uuid,
        :route_type => self.route_type,
        :ipv4_network => self.ipv4_network,
        :ipv4_prefix => self.ipv4_prefix,
        :ingress => self.ingress,
        :egress => self.egress,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
