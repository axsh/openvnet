# -*- coding: utf-8 -*-

module Vnet::Core::Connections

  # UDP is a connectionless protocol but we're not doing real connection
  # tracking here. When we send out a packet, we just open up the source port
  # so we can receive a reply.
  class UDP < Base
    def match_egress(message)
      {
        ip_proto: IPV4_PROTOCOL_UDP,
        udp_src:  message.udp_src,
        udp_dst:  message.udp_dst
      }
    end

    def match_ingress(message)
      {
        ip_proto: IPV4_PROTOCOL_UDP,
        udp_src:  message.udp_dst,
        udp_dst:  message.udp_src
      }
    end
  end
end
