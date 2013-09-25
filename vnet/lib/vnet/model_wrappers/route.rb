# -*- coding: utf-8 -*-
require 'ipaddress'

module Vnet::ModelWrappers
  class Route < Base

    def to_hash
      interface = self.batch.interface.commit
      {
        :uuid => self.uuid,
        :route_link_uuid => self.batch.route_link.commit.uuid,
        :interface_uuid => interface && interface.uuid,
        :route_type => self.route_type,
        :ipv4_address => IPAddress::IPv4::parse_u32(self.ipv4_address).to_s,
        :ipv4_prefix => self.ipv4_prefix,
        :ingress => self.ingress,
        :egress => self.egress,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
