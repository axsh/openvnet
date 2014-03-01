# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class SecurityGroup < Base
    include Celluloid::Logger

    RULE_PRIORITY = 10
    ISOLATION_PRIORITY = 20

    REF_REGEX = /sg-.{1,8}[a-z1-9]$/

    attr_reader :id, :uuid, :interfaces

    def initialize(item_map)
      @id = item_map.id
      @uuid = item_map.uuid
      @rules, @referencees = parse_rules(item_map.rules)

      # This is going to hold the ip addresses of all our 'friends'. All
      # interfaces in this group will accept all traffic from these addresses.
      # Basically all interfaces in this group accept all L3 traffic from all
      # other interfaces in this group.
      @isolation_ips = item_map.ip_addresses

      # Interfaces holds a hash of this format:
      # { interface_id => interface_cookie_id }
      @interfaces = {}
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
      install_reference(interface_id)
    end

    def uninstall(interface_id)
      uninstall_rules(interface_id)
      uninstall_isolation(interface_id)
      #TODO: Uninstall reference rules
      @interfaces.delete(interface_id)
    end

    def update_rules(rules)
      uninstall_rules
      @rules = split_rules(rules)
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
    def rule_to_match(protocol, port, ipv4)
      #TODO: Handle the situation when protocol isn't a proper protocol
      match_ipv4_subnet_src(ipv4.u32, ipv4.prefix.to_i).merge case protocol
      when 'icmp'
        { ip_proto: IPV4_PROTOCOL_ICMP }
      when 'tcp'
        { ip_proto: IPV4_PROTOCOL_TCP, tcp_dst: port }
      when 'udp'
        { ip_proto: IPV4_PROTOCOL_UDP, udp_dst: port }
      end
    end

    def parse_rules(rules)
      #TODO: Throw away commented and invalid rules. Also log a warning for
      #invalid rules
      rules, reference = split_rules(rules).partition { |r|
        (r =~ REF_REGEX).nil?
      }

      ref_hash = Hash.new.tap { |rh| reference.each { |r|
        referencee_uuid = r.split(":").last
        referencee = Vnet::ModelWrappers::SecurityGroup.batch[referencee_uuid].commit

        rh[referencee.id] = {
          uuid: referencee.uuid,
          rule: r,
          ipv4s: referencee.batch.ip_addresses.commit
        }
      }}

      [rules, ref_hash]
    end

    def split_rules(rules)
      rules.split("\n")
    end

    def install_rules(interface_id = nil)
      interface_ids = if interface_id
        [interface_id]
      else
        @interfaces.keys
      end

      flows = interface_ids.map { |interface_id|
        @rules.map do |rule|
          #TODO: Handle the situation when ipv4 isn't a valid ip address
          protocol, port, ipv4 = rule.strip.split(":")
          ipv4 = IPAddress::IPv4.new(ipv4)
          port = port.to_i

          flow_create(:default,
            table: TABLE_INTERFACE_INGRESS_FILTER,
            priority: RULE_PRIORITY,
            match_interface: interface_id,
            cookie: cookie(COOKIE_TYPE_RULE, interface_id),
            match: rule_to_match(protocol, port, ipv4),
            goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
          )
        end
      }.flatten

      @dp_info.add_flows(flows)
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

    def install_reference(interface_id = nil)
      rules = @referencees.values.map { |referencee|
        referencee[:ipv4s].map { |ipv4|
          referencee[:rule].gsub(REF_REGEX, ipv4.to_s)
        }
      }.flatten

      interface_ids = if interface_id
        [interface_id]
      else
        @interfaces.keys
      end

      flows = interface_ids.map { |interface_id|
        rules.map do |rule|
          protocol, port, ipv4 = rule.strip.split(":")
          #TODO: Fucking improve this... you're converting an integer to string and
          #converting it back to integer afterwards, you dumb twit! (me talking to myself)
          ipv4 = IPAddress::IPv4.parse_u32(ipv4.to_i)

          flow_create(:default,
            table: TABLE_INTERFACE_INGRESS_FILTER,
            priority: RULE_PRIORITY,
            match_interface: interface_id,
            cookie: cookie(COOKIE_TYPE_REF, interface_id),
            match: rule_to_match(protocol, port.to_i, ipv4),
            goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
          )
        end
      }.flatten

      @dp_info.add_flows(flows)
    end

    { isolation: COOKIE_TYPE_ISO, rules: COOKIE_TYPE_RULE }.each do |name, cookie_type|
      define_method("uninstall_#{name}") { |interface_id = nil|
        if interface_id
          @dp_info.del_cookie cookie(cookie_type, interface_id)
        else
          @dp_info.del_cookie(
            COOKIE_TYPE_FILTER | cookie_type      | @id,
            COOKIE_PREFIX_MASK | COOKIE_TYPE_MASK | COOKIE_ID_MASK
          )
        end
      }
    end
  end

end
