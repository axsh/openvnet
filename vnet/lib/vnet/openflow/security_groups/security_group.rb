# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::Openflow::SecurityGroups
  class SecurityGroup
    include Vnet::Openflow::FlowHelpers
    include Celluloid::Logger

    def initialize(params)
      @id = params.id
      @uuid = params.uuid
      @rules = params.rules
    end

    def cookie
      @id | (COOKIE_PREFIX_SECURITY_GROUP << COOKIE_PREFIX_SHIFT)
    end

    def install(interface)
      debug "installing security group '#{@uuid}' for interface '#{interface.uuid}'"
      @rules.split("\n").map { |r| rule_to_flow(interface, r) }
    end

    private
    # def match_ipv4_subnet_src_icmp(address, prefix)
    #   match_ipv4_subnet_src(address, prefix).merge({

    #   })
    # end

    def rule_to_flow(interface, rule)
      debug "installing rule: '#{rule}'"
      protocol, ports, ipv4 = rule.split(":")
      from_port, to_port = ports.split(",")
      # ipv4_address, ipv4_prefix = ipv4.split("/")
      # ipv4_prefix ||= 32
      #TODO: Get rid of this quick dirty hack
      # ipv4_prefix = ipv4_prefix.to_i
      ipv4 = IPAddress::IPv4.new(ipv4)

      flow_create(:default,
        table: TABLE_INTERFACE_INGRESS_FILTER,
        priority: 10,
        match_metadata: {
          :interface => interface.id
        },
        match: match_ipv4_subnet_src(ipv4.u32, ipv4.prefix.to_i),
        cookie: cookie,
        goto_table: TABLE_INTERFACE_VIF)
    end
  end
end
