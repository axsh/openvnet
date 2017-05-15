# -*- coding: utf-8 -*-

module Vnet::Constants::FilterStatic
  PROTOCOL_TCP  = 'tcp'
  PROTOCOL_UDP  = 'udp'
  PROTOCOL_ICMP = 'icmp'
  PROTOCOL_ARP  = 'arp'
  PROTOCOL_IP   = 'ip'

  PROTOCOLS = [
    PROTOCOL_TCP,
    PROTOCOL_UDP,
    PROTOCOL_ICMP,
    PROTOCOL_ARP,
    PROTOCOL_IP
  ]
end
