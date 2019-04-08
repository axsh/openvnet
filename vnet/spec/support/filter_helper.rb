# coding: utf-8

def flow(params)
  flow_create(
    table: params[:table],
    goto_table: params[:goto_table],
    priority: params[:priority],

    match_value_pair_first: params[:interface_id],
    match: params[:match],

    cookie: params[:id] | COOKIE_TYPE_FILTER,
  )
end

def deleted_flow(params)
  {
    table_id: params[:table],
    cookie: params[:id] | COOKIE_TYPE_FILTER,
    cookie_mask: Vnet::Constants::OpenflowFlows::COOKIE_MASK,
    match: params[:match]
  }
end

def ingress_tables(pass)
   {
    table: TABLE_INTERFACE_INGRESS_FILTER,
    goto_table: pass ? TABLE_OUT_PORT_INTERFACE_INGRESS : nil
   }
end

def egress_tables(pass)
  {
    table: TABLE_INTERFACE_EGRESS_FILTER_IF_NIL,
    goto_table: pass ? TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL : nil,
  }
end

def protocol_type_egress(protocol, port_number)
  case protocol
    when 'tcp' then
      { ip_proto: IPV4_PROTOCOL_TCP, tcp_dst: port_number }
    when 'udp' then
      { ip_proto: IPV4_PROTOCOL_UDP, udp_dst: port_number }
    when 'icmp' then
      { ip_proto: IPV4_PROTOCOL_ICMP }
    else
      return;
    end
end

def protocol_type_ingress(protocol, port_number)
  case protocol
    when 'tcp' then
      { ip_proto: IPV4_PROTOCOL_TCP, tcp_src: port_number }
    when 'udp' then
      { ip_proto: IPV4_PROTOCOL_UDP, udp_src: port_number }
    when 'icmp' then
      { ip_proto: IPV4_PROTOCOL_ICMP }
    else
      return;
    end
end

def arp_match_src(ipv4_address, prefix)
  {
    eth_type: ETH_TYPE_ARP,
    arp_spa: ipv4_address,
    arp_spa_mask: IPV4_BROADCAST << (32 - prefix)
  }
end

def arp_match_dst(ipv4_address, prefix)
  {
    eth_type: ETH_TYPE_ARP,
    arp_tpa: ipv4_address,
    arp_tpa_mask: IPV4_BROADCAST << (32 - prefix)
  }
end

def rule(traffic_direction, protocol, ipv4_address, prefix, port_number = nil)
  case traffic_direction
  when 'egress' then
    return arp_match_dst(ipv4_address, prefix) if protocol == 'arp'
    match_ipv4_subnet_dst(ipv4_address, prefix).merge(protocol_type_egress(protocol, port_number))
  when 'ingress' then
    return arp_match_src(ipv4_address, prefix) if protocol == 'arp'
    match_ipv4_subnet_src(ipv4_address, prefix).merge(protocol_type_ingress(protocol, port_number))
  else
    return
  end
end

def static_priority(src_prefix:, dst_prefix:, port_src:, port_dst:, **)
  20 + ((dst_prefix * 2) + ((port_dst.nil? || port_dst == 0) ? 0 : 1)) * 66 +
    (src_prefix * 2) + ((port_src.nil? || port_src == 0) ? 0 : 1)
end

def static_hash(static)
  { [ filter.to_hash,
      ingress_tables(static.action == 'pass'),
      { priority: static_priority(static) },
      { match: rule('ingress',
                    static.protocol,
                    static.src_address,
                    static.src_prefix,
                    static.port_src) }
    ].inject(&:merge) => [
      filter.to_hash,
      egress_tables(static.action == 'pass'),
      { priority: static_priority(static) },
      { match: rule('egress',
                    static.protocol,
                    static.src_address,
                    static.src_prefix,
                    static.port_src) }
    ].inject(&:merge)
  }
end

def filter_hash(filter)
  { [ filter.to_hash, ingress_tables(filter.ingress_passthrough), { priority: 10 } ].inject(&:merge) =>
    [ filter.to_hash, egress_tables(filter.egress_passthrough), { priority: 10 } ].inject(&:merge)
  }
end
