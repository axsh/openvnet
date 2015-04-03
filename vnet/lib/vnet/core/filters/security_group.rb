# -*- coding: utf-8 -*-

module Vnet::Core::Filters
  class SecurityGroup < Base
    include Celluloid::Logger
    include Vnet::Helpers::SecurityGroup

    RULE_PRIORITY = 10
    ISOLATION_PRIORITY = 20

    attr_reader :id, :uuid, :interfaces

    #TODO:
    # Currently we are rebuilding ALL reference rules when ips are updated,
    # even the ones from groups that didn't have their ips updated. This is
    # because I haven't found a good way to separate referencees in the cookie
    # yet. Would be nice if we could optimize that.
    # Same goes for the #remove_referencee method

    #TODO:
    # Currently isolation creates the same flows for every interface in a group.
    # It would be a lot better if we could combine those together somehow.
    # Perhaps using metadata?

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

    def references?(secg_id)
      @referencees.member? secg_id
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

    def remove_referencee(id)
      @referencees.delete(id) || return

      uninstall_reference
      @dp_info.add_flows flows_for_reference
    end

    # If interface_id is nil, the group will be installed for all interfaces in it
    def install(interface_id = nil)
      @dp_info.add_flows(
        flows_for_rules(interface_id) +
        flows_for_isolation(interface_id) +
        flows_for_reference(interface_id)
      )
    end

    def uninstall(interface_id = nil)
      uninstall_rules(interface_id)
      uninstall_isolation(interface_id)
      uninstall_reference(interface_id)
      @interfaces.delete(interface_id)
    end

    def update_rules(rules)
      uninstall_rules
      uninstall_reference
      @rules, @referencees = parse_rules(rules)
      @dp_info.add_flows(flows_for_rules + flows_for_reference)
    end

    def update_referencee(referencee_id, ipv4s)
      uninstall_reference
      @referencees[referencee_id][:ipv4s] = ipv4s
      @dp_info.add_flows flows_for_reference
    end

    def update_isolation(ip_addresses)
      uninstall_isolation
      @isolation_ips = ip_addresses
      @dp_info.add_flows flows_for_isolation
    end

    private
    def rule_to_match(protocol, port, ipv4)
      prefix = ipv4.to_i == 0 ? 0 : ipv4.prefix.to_i
      match_ipv4_subnet_src(ipv4.u32, prefix).merge case protocol
      when 'icmp'
        { ip_proto: IPV4_PROTOCOL_ICMP }
      when 'tcp'
        { ip_proto: IPV4_PROTOCOL_TCP, tcp_dst: port }
      when 'udp'
        { ip_proto: IPV4_PROTOCOL_UDP, udp_dst: port }
      end
    end

    def parse_rules(rules)
      rules_array = split_multiline_rules_string(rules)

      # The model class doesn't allow rules with syntax errors to be saved but
      # we check here again in case somebody put them in the database without
      # going through the model class' validation hooks
      remove_malformed_rules!(rules_array)

      normal_rules = []
      ref_hash = Hash.new

      rules_array.each { |r|
        protocol, port, ip_or_uuid = split_rule(r)
        is_reference_rule = !(ip_or_uuid =~ uuid_regex).nil?

        if is_reference_rule
          referencee = Vnet::ModelWrappers::SecurityGroup.batch[ip_or_uuid].commit

          if referencee.nil?
            warn log_format("'#{@uuid}': Unknown security group uuid in rule: '#{r}'")
            next
          end

          ref_hash[referencee.id] = {
            uuid: referencee.uuid,
            rule: r,
            ipv4s: referencee.batch.ip_addresses.commit
          }
        else
          normal_rules << r
        end
      }

      [normal_rules, ref_hash]
    end

    def remove_malformed_rules!(rules_array)
      rules_array.map! { |r|
        rule_is_valid, error_msg = validate_rule(r)

        unless rule_is_valid
          warn log_format(error_msg, " #{@uuid}: '#{r}'")
          next
        end

        r
      }

      rules_array.compact!
    end

    def log_format(msg, values = nil)
      "security_group: " + msg + (values ? " (#{values})" : '')
    end

    def flows_for_rules(interface_id = nil)
      flows = interface_ids(interface_id).map { |interface_id|
        @rules.map do |rule|
          protocol, port, ipv4 = split_rule(rule)

          build_rule_flow(protocol, port, IPAddress::IPv4.new(ipv4), interface_id)
        end
      }.flatten
    end

    def flows_for_isolation(interface_id = nil)
      interface_ids(interface_id).map { |interface_id|
        @isolation_ips.map { |ip|
          flow_create(table: TABLE_INTERFACE_INGRESS_FILTER,
                      goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                      priority: ISOLATION_PRIORITY,
                      match_interface: interface_id,
                      cookie: cookie(COOKIE_TYPE_ISO, interface_id),
                      match: match_ipv4_subnet_src(ip, 32))
        }
      }.flatten
    end

    def flows_for_reference(interface_id = nil)
      @referencees.values.map { |referencee|
        referencee[:ipv4s].map { |ipv4|
          protocol, port = referencee[:rule].split(":")
          ip_addr = IPAddress::IPv4.parse_u32(ipv4)

          interface_ids(interface_id).map { |interface_id|
            build_rule_flow(protocol, port, ip_addr, interface_id, COOKIE_TYPE_REF)
          }
        }
      }.flatten
    end

    def build_rule_flow(protocol, port, ipv4, interface_id, cookie_type = COOKIE_TYPE_RULE)
      flow_create(table: TABLE_INTERFACE_INGRESS_FILTER,
                  goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                  priority: RULE_PRIORITY,
                  match_interface: interface_id,
                  cookie: cookie(cookie_type, interface_id),
                  match: rule_to_match(protocol, port.to_i, ipv4))
    end

    def interface_ids(interface_id)
      interface_id ? [interface_id] : @interfaces.keys
    end

    {isolation: COOKIE_TYPE_ISO,
    rules: COOKIE_TYPE_RULE,
    reference: COOKIE_TYPE_REF}.each do |name, cookie_type|
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
