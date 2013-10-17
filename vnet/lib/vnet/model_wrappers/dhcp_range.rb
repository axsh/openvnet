# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class DhcpRange < Base
    def range_begin_s
      self.range_begin && IPAddress::IPv4::parse_u32(self.range_begin).to_s
    end

    def range_end_s
      self.range_end && IPAddress::IPv4::parse_u32(self.range_end).to_s
    end
  end
end
