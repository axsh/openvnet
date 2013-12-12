# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::Openflow::Filters
  class Rule
    include Vnet::Openflow::FlowHelpers
    include Celluloid::Logger

    RULE_PRIORITY = 10

    attr_reader :cookie

    def initialize(s_ipv4, port, cookie)
      @s_ipv4 = IPAddress::IPv4.new(s_ipv4)
      @cookie = cookie
      @port = port.to_i
    end

    def install(interface)
      flow_create(
        :default,
        table: TABLE_INTERFACE_INGRESS_FILTER,
        priority: RULE_PRIORITY,
        match_metadata: {interface: interface.id},
        match: match_ipv4_subnet_src(@s_ipv4.u32, @s_ipv4.prefix.to_i).merge(match),
        cookie: @cookie,
        goto_table: TABLE_OUTPUT_INTERFACE_INGRESS
      )
    end
  end

  class ICMP < Rule
    def match
      {ip_proto: IPV4_PROTOCOL_ICMP}
    end
  end

  class TCP < Rule
    def match
      {
        ip_proto: IPV4_PROTOCOL_TCP,
        tcp_dst: @port.to_i
      }
    end
  end

  class UDP < Rule
    def match
      {
        ip_proto: IPV4_PROTOCOL_UDP,
        udp_dst: @port.to_i
      }
    end
  end
end
