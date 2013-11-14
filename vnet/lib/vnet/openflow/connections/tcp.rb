# -*- coding: utf-8 -*-

module Vnet::Openflow::Connections
  class TCP < Base
    def log_new_open(interface, message)
      debug "'%s' Opening new tcp connection %s:%s => %s:%s" %
        [interface.uuid, message.ipv4_src, message.tcp_src, message.ipv4_dst, message.tcp_dst]
    end

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
