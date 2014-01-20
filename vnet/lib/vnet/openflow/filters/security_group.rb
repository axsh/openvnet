# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class SecurityGroup < Base
    include Celluloid::Logger

    RULE_PRIORITY = 10

    attr_reader :id, :uuid

    def initialize(params)
      @id = params[:id]
      @uuid = params[:uuid]
      @interface_id = params[:interface_id]
      @interface_cookie_id = params[:interface_cookie_id]
      @rules = params[:rules]
      #TODO: Create reference rules
      #TODO: Create isolation
    end

    def self.cookie(group_id, interface_cookie_id, type)
      types = {
        rule: COOKIE_TYPE_RULE,
        reference: COOKIE_TYPE_REF,
        isolation: COOKIE_TYPE_ISO
      }

      group_id | COOKIE_TYPE_FILTER | types[type] |
        (interface_cookie_id << COOKIE_TYPE_VALUE_SHIFT)
    end

    def cookie(type)
      self.class.cookie(@id, @interface_cookie_id, type)
    end

    def install
      install_rules
      #TODO: Install reference rules
      #TODO: Install isolation
    end

    def uninstall
      uninstall_rules
      #TODO: Uninstall reference rules
      #TODO: Uninstall isolation
    end

    def update_rules(rules)
      uninstall_rules
      @rules = rules
      install_rules
    end

    def update_reference
      #TODO: Implement
    end

    def update_isolation
      #TODO: Implement
    end

    private
    def rule_to_match(rule)
      protocol, port, ipv4 = rule.strip.split(":")
      #TODO: Handle the situation when ipv4 isn't a valid ip address
      ipv4 = IPAddress::IPv4.new(ipv4)
      port = port.to_i

      match_ipv4_subnet_src(ipv4.u32, ipv4.prefix.to_i).merge case protocol
        when 'icmp'
          { ip_proto: IPV4_PROTOCOL_ICMP }
        when 'tcp'
          { ip_proto: IPV4_PROTOCOL_TCP, tcp_dst: port }
        when 'udp'
          { ip_proto: IPV4_PROTOCOL_UDP, udp_dst: port }
        end
    end

    def install_rules
      @rules.split("\n").each do |rule|
        rule_flow = flow_create(:default,
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: RULE_PRIORITY,
          match_metadata: {interface: @interface_id},
          cookie: cookie(:rule),
          match: rule_to_match(rule),
          goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
        )

        @dp_info.add_flow(rule_flow)
      end
    end

    def uninstall_rules
      @dp_info.del_cookie cookie(:rule)
    end
  end

end
