# -*- coding: utf-8 -*-
require 'ipaddress'

module Vnet::Helpers::SecurityGroup
  COMMENT_REGEX = /^#.*/

  def uuid_regex
    Vnet::Endpoints::V10::Helpers::UUID.regex('sg')
  end

  def validate_protocol(protocol)
    ['icmp', 'tcp', 'udp'].member?(protocol)
  end

  def validate_port(port)
    (1..0xffff).member?(port.to_i)
  end

  def validate_ipv4_or_uuid(value)
    (IPAddress(value) rescue false) || value == '0.0.0.0/0' || !(value =~ uuid_regex).nil?
  end

  def is_reference_rule?(rule)
    !(split_rule(rule)[2] =~ uuid_regex).nil?
  end

  def validate_rule(rule)
    protocol, port, ipv4 = split_rule(rule)

    return false, 'invalid protocol in rule' unless validate_protocol(protocol)
    return false, 'invalid port in rule' unless protocol == 'icmp' || validate_port(port)

    unless validate_ipv4_or_uuid(ipv4)
      return false, 'invalid ipv4 address or security group uuid in rule'
    end

    true
  end

  def split_rule(rule)
    rule.split(':')
  end

  def split_multiline_rules_string(rules)
    # remove comments
    rules = rules.gsub(/#.*(\r\n|\r|\n|$)/, "")

    # split based on comma or newline
    rules = rules.split(/,|\r\n|\r|\n/)

    # remove trailing or leading whitespace
    rules.map! { |r| r.strip }

    # remove empty lines
    rules.select { |r| !r.empty? }
  end
end
