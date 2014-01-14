# -*- coding: utf-8 -*-

def cookie_id(group)
  Vnet::Openflow::Filters::SecurityGroup.cookie(
    group.id,
    group.interface_cookie_id(interface.id)
  )
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

def rule_flow(rule_hash)
  flow_hash = rule_hash.merge({
    table: TABLE_INTERFACE_INGRESS_FILTER,
    priority: Vnet::Openflow::Filters::Rule::PRIORITY,
    match_metadata: {interface: interface.id},
    goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
  })

  flow_create(:default, flow_hash)
end
