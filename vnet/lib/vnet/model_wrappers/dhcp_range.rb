# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class DhcpRange < Base
    def range_begin_s
      self.range_begin && IPAddress::IPv4::parse_u32(self.range_begin).to_s
    end

    def range_end_s
      self.range_end && IPAddress::IPv4::parse_u32(self.range_end).to_s
    end

    def to_hash
      network = self.batch.network.commit
      {
        :uuid => self.uuid,
        :network_uuid => network && network.uuid,
        :range_begin => self.range_begin_s,
        :range_end => self.range_end_s,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
