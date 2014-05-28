# -*- coding: utf-8 -*-

def cookie_id(group, interface = interface, type = Vnet::Core::Filters::Base::COOKIE_TYPE_RULE)
  Vnet::Core::Filters::SecurityGroup.cookie(
    group.id,
    group.interface_cookie_id(interface.id),
    type
  )
end

def ref_cookie_id(group, interface = interface)
  cookie_id(group, interface, Vnet::Core::Filters::Base::COOKIE_TYPE_REF)
end

def wrapper(interface)
  Vnet::ModelWrappers::Interface.batch[interface.id].commit
end

def match_rule(source_ip)
  ip = IPAddress::IPv4.new(source_ip)
  match_ipv4_subnet_src(ip.u32, ip.prefix.to_i)
end

def match_tcp_rule(source_ip, port)
  match_rule(source_ip).merge({
    ip_proto: IPV4_PROTOCOL_TCP,
    tcp_dst: port
  })
end

def match_udp_rule(source_ip, port)
  match_rule(source_ip).merge({
    ip_proto: IPV4_PROTOCOL_UDP,
    udp_dst: port
  })
end

def match_icmp_rule(source_ip)
  match_rule(source_ip).merge({ ip_proto: IPV4_PROTOCOL_ICMP })
end

def rule_flow(rule_hash, interface = interface)
  flow_hash = rule_hash.merge({
    table: TABLE_INTERFACE_INGRESS_FILTER,
    priority: Vnet::Core::Filters::SecurityGroup::RULE_PRIORITY,
    match_metadata: {interface: interface.id},
    goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
  })

  flow_create(flow_hash)
end

def reference_flows_for(rule, interface)
  protocol, port = rule.split(':')

  interface.ip_addresses.map { |a|
    match = if protocol == 'icmp'
      match_icmp_rule("#{a.ipv4_address_s}/32")
    else
      send("match_#{protocol}_rule", "#{a.ipv4_address_s}/32", port.to_i)
    end

    rule_flow(
      cookie: ref_cookie_id(group),
      match: match
    )
  }
end

def iso_flow(group, interface, ipv4_address)
  flow_create(table: TABLE_INTERFACE_INGRESS_FILTER,
              goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
              priority: Vnet::Core::Filters::SecurityGroup::ISOLATION_PRIORITY,
              match_interface: interface.id,
              match: match_ipv4_subnet_src(ipv4_address, 32),
              cookie: cookie_id(group, interface, Vnet::Core::Filters::Base::COOKIE_TYPE_ISO))
end

def iso_flows_for_interfaces(group, main_interface, iso_interfaces)
  ip_leases = iso_interfaces.map { |iif| iif.ip_leases }.flatten
  ip_leases.map do |ip_lease|
    iso_flow(group, main_interface, ip_lease.ipv4_address)
  end
end
