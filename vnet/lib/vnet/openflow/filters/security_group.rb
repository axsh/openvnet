# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class SecurityGroup < Base
    include Celluloid::Logger

    RULE_PRIORITY = 10
    ISOLATION_PRIORITY = 20

    attr_reader :id, :uuid, :interfaces

    def initialize(item_map)
      @id = item_map.id
      @uuid = item_map.uuid
      @rules = item_map.rules

      # This is going to hold the ip addresses of all our 'friends'. All
      # interfaces in this group will accept all traffic from these addresses.
      # Basically all interfaces in this group accept all L3 traffic from all
      # other interfaces in this group.
      @isolation_ips = item_map.ip_addresses

      # Interfaces holds a hash of this format:
      # { interface_id => interface_cookie_id }
      @interfaces = {}
      #TODO: Create reference rules
    end

    def self.cookie(group_id, interface_cookie_id, cookie_type)
      group_id | COOKIE_TYPE_FILTER | cookie_type |
        (interface_cookie_id << COOKIE_TYPE_VALUE_SHIFT)
    end

    def cookie(type, interface_id)
      self.class.cookie(@id, @interfaces[interface_id], type)
    end

    def has_interface?(interface_id)
      @interfaces.has_key?(interface_id)
    end

    def add_interface(interface_id, interface_cookie_id)
      @interfaces[interface_id] = interface_cookie_id
    end

    def remove_interface(interface_id)
      @interfaces.delete(interface_id)
    end

    def install(interface_id = nil)
      install_rules(interface_id)
      install_isolation(interface_id)
      #TODO: Install reference rules
    end

    def uninstall(interface_id)
      uninstall_rules(interface_id)
      uninstall_isolation(interface_id)
      #TODO: Uninstall reference rules
      @interfaces.delete(interface_id)
    end

    def update_rules(rules)
      uninstall_rules
      @rules = rules
      install_rules
    end

    def update_reference
      #TODO: Implement
    end

    def update_isolation(ip_addresses)
      uninstall_isolation
      @isolation_ips = ip_addresses
      install_isolation
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

    def install_rules(interface_id = nil)
      interface_ids = if interface_id
        [interface_id]
      else
        @interfaces.keys
      end

      flows = interface_ids.map { |interface_id|
        @rules.split("\n").map do |rule|
          flow_create(:default,
            table: TABLE_INTERFACE_INGRESS_FILTER,
            priority: RULE_PRIORITY,
            match_interface: interface_id,
            cookie: cookie(COOKIE_TYPE_RULE, interface_id),
            match: rule_to_match(rule),
            goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
          )
        end
      }.flatten

      @dp_info.add_flows(flows)
    end

    def uninstall_rules(interface_id = nil)
      #TODO: Use a proper cookie mask instead
      interface_ids = if interface_id
        [interface_id]
      else
        @interfaces.keys
      end

      interface_ids.each do |id|
        @dp_info.del_cookie cookie(COOKIE_TYPE_RULE, id)
      end
    end

    def install_isolation(interface_id = nil)
      interface_ids = if interface_id
        [interface_id]
      else
        @interfaces.keys
      end

      flows = interface_ids.map { |interface_id|
        @isolation_ips.map { |ip|
          flow_create(:default,
            table: TABLE_INTERFACE_INGRESS_FILTER,
            priority: ISOLATION_PRIORITY,
            match_interface: interface_id,
            cookie: cookie(COOKIE_TYPE_ISO, interface_id),
            match: match_ipv4_subnet_src(ip, 32),
            goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
          )
        }
      }.flatten

      @dp_info.add_flows(flows)
    end

    def uninstall_isolation(interface_id = nil)
      #TODO: Use a proper cookie mask instead
      interface_ids = if interface_id
        [interface_id]
      else
        @interfaces.keys
      end

      interface_ids.each do |id|
        @dp_info.del_cookie cookie(COOKIE_TYPE_ISO, id)
      end
    end
  end

end
