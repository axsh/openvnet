# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::Openflow::Filters
  class Rule < Base
    include Celluloid::Logger

    PRIORITY = 10

    attr_reader :cookie

    def self.create(rule_string, interface_id, cookie)
      protocol, port, ipv4 = rule_string.strip.split(":")
      case protocol
      when 'icmp'
        ICMP.new(ipv4, interface_id, cookie)
      when 'tcp'
        TCP.new(ipv4, port, interface_id, cookie)
      when 'udp'
        UDP.new(ipv4, port, interface_id, cookie)
      end
    end

    def initialize(s_ipv4, port, interface_id, cookie)
      @s_ipv4 = IPAddress::IPv4.new(s_ipv4)
      @port = port.to_i
      @interface_id = interface_id
      @cookie = cookie
    end

    def install
      @dp_info.add_flow(
        flow_create(
          :default,
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: PRIORITY,
          match_metadata: {interface: @interface_id},
          match: match_ipv4_subnet_src(@s_ipv4.u32, @s_ipv4.prefix.to_i).merge(match),
          goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
        )
      )
    end
  end

  class ICMP < Rule
    def initialize(s_ipv4, interface_id, cookie)
      super(s_ipv4, nil, interface_id, cookie)
    end

    def match
      {ip_proto: IPV4_PROTOCOL_ICMP}
    end
  end

  class TCP < Rule
    def match
      {
        ip_proto: IPV4_PROTOCOL_TCP,
        tcp_dst: @port
      }
    end
  end

  class UDP < Rule
    def match
      {
        ip_proto: IPV4_PROTOCOL_UDP,
        udp_dst: @port
      }
    end
  end
end
