# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::Openflow::SecurityGroups
  IDLE_TIMEOUT  = 1200

  class Rule
    include Vnet::Openflow::FlowHelpers
    include Celluloid::Logger

    attr_reader :cookie

    def initialize(s_ipv4, port, cookie)
      @s_ipv4 = IPAddress::IPv4.new(s_ipv4)
      @cookie = cookie
      @port = port.to_i
    end

    RULE_PRIORITY = 10

    def install(interface)
      flow_create(
        :default,
        table: TABLE_INTERFACE_INGRESS_FILTER,
        priority: RULE_PRIORITY,
        match_metadata: {interface: interface.id},
        match: match_ipv4_subnet_src(@s_ipv4.u32, @s_ipv4.prefix.to_i).merge(match),
        cookie: @cookie,
        idle_timeout: IDLE_TIMEOUT,
        goto_table: TABLE_INTERFACE_VIF
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

  class SecurityGroup
    include Vnet::Openflow::FlowHelpers
    include Celluloid::Logger

    SGM = Vnet::Openflow::SecurityGroupManager

    attr_reader :id, :uuid

    def initialize(group_wrapper, interface_id)
      @udp_rules = []; @tcp_rules = []; @icmp_rules = []
      @id = group_wrapper.id
      @uuid = group_wrapper.uuid
      @interface_cookie_id = group_wrapper.batch.interface_cookie_id(interface_id).commit
      group_wrapper.rules.split("\n").each {|line| rule_factory(line) }
    end

    def cookie
      @id | COOKIE_TYPE_SECURITY_GROUP | SGM::COOKIE_SG_TYPE_RULE |
        (@interface_cookie_id << SGM::COOKIE_TYPE_VALUE_SHIFT)
    end

    def install(interface)
      debug "installing security group '#{@uuid}' for interface '#{interface.uuid}'"
      (@icmp_rules + @udp_rules + @tcp_rules).map { |r| r.install(interface) } <<
      install_drop_flow(interface)
    end

    private
    def install_drop_flow(interface)
      flow_create(:default,
                  table: TABLE_INTERFACE_INGRESS_FILTER,
                  priority: 2,
                  idle_timeout: IDLE_TIMEOUT,
                  match_metadata: { interface: interface.id},
                  cookie: cookie)
    end

    def rule_factory(rule_string)
      protocol, port, ipv4 = rule_string.split(":")
      case protocol
      when 'icmp'
        @icmp_rules << ICMP.new(ipv4, port, cookie)
      when 'tcp'
        @tcp_rules << TCP.new(ipv4, port, cookie)
      when 'udp'
        @udp_rules << UDP.new(ipv4, port, cookie)
      end
    end
  end

end
