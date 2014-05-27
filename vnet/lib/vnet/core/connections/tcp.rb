# -*- coding: utf-8 -*-

module Vnet::Core::Connections
  class TCP < Base
    def match_egress(message)
      {
        ip_proto: IPV4_PROTOCOL_TCP,
        tcp_src:  message.tcp_src,
        tcp_dst:  message.tcp_dst
      }
    end

    def match_ingress(message)
      {
        ip_proto: IPV4_PROTOCOL_TCP,
        tcp_src:  message.tcp_dst,
        tcp_dst:  message.tcp_src
      }
    end
  end
end
