# -*- coding: utf-8 -*-

module Vnet::Helpers::IpAddress
  
  def valid_in_subnet(network, ipv4_address)

    ipv4_nw = IPAddress::IPv4::parse_u32(network.ipv4_network, network.ipv4_prefix)
    ipv4 = IPAddress::IPv4::parse_u32(ipv4_address, network.ipv4_prefix)
  
    ipv4_nw.include? (ipv4)
  end
end
