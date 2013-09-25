# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class IpAddress < Base

    def to_hash
      {
        :uuid => self.uuid,
        :ipv4_address => IPAddress::IPv4::parse_u32(self.ipv4_address).to_s,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
