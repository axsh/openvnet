# -*- coding: utf-8 -*-

module Vnet::Openflow::SecurityGroups
  class Group
    include Vnet::Constants::OpenflowFlows
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
      (@icmp_rules + @udp_rules + @tcp_rules).map { |r| r.install(interface) }
    end

    private
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
