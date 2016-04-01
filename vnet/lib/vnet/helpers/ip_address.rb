# -*- coding: utf-8 -*-

module Vnet::Helpers
  class IpAddress

    def self.valid_in_subnet(network, ipv4_address)
      if (ipv4_address == 0)
        return true
      end
      ipv4_nw = IPAddress::IPv4::parse_u32(network.ipv4_network, network.ipv4_prefix)
      ipv4 = IPAddress::IPv4::parse_u32(ipv4_address, network.ipv4_prefix)

      return ipv4_nw.include?(ipv4), ipv4_nw, ipv4
    end
  end
end
