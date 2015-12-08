# coding: utf-8

def flow(params)
  flow_create(
    table: params[:table],
    goto_table: params[:goto_table],
    priority: params[:priority],
    match_interface: params[:interface_id],
    cookie: params[:id] | COOKIE_TYPE_FILTER2,
    match: params[:match]
  )
end

def deleted_flow(params)
  {
    table_id: params[:table],
    cookie: params[:id] | COOKIE_TYPE_FILTER2,
    cookie_mask: Vnet::Constants::OpenflowFlows::COOKIE_MASK,
    match: params[:match]
  }
end

def ingress_tables(passthrough)
   {
    table: TABLE_INTERFACE_INGRESS_FILTER,
    goto_table: passthrough ? TABLE_OUT_PORT_INTERFACE_INGRESS : nil
   }
end

def egress_tables(passthrough)
  {
    table: TABLE_INTERFACE_EGRESS_FILTER,
    goto_table: passthrough ? TABLE_INTERFACE_EGRESS_VALIDATE : nil,
  }
end

def protocol_type(protocol, port_number)
  case protocol
    when "tcp" then
      {
        ip_proto: IPV4_PROTOCOL_TCP,
        tcp_dst: port_number
      }
    when "udp" then
      {
        ip_proto: IPV4_PROTOCOL_UDP,
        udp_dst: port_number
      }
    when "icmp" then
      {
        ip_proto: IPV4_PROTOCOL_ICMP
      }
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
  when "ingress" then
    return arp_match_src(ipv4_address, prefix) if protocol == "arp"
    match_ipv4_subnet_src(ipv4_address, prefix).merge(protocol_type(protocol, port_number))
  when "egress" then
    return arp_match_dst(ipv4_address, prefix) if protocol == "arp"
    match_ipv4_subnet_dst(ipv4_address, prefix).merge(protocol_type(protocol, port_number))
  else
    return
  end
end

def static_priority(prefix, passthrough, port = nil)
  (prefix << 1) + ((port.nil? || port == 0) ? 0 : 2) + (passthrough ? 1 : 0)
end

def static_hash(static, protocol)
  {
    [
      filter.to_hash,
      ingress_tables(static.passthrough),
      { priority: 20 + static_priority(static.ipv4_src_prefix,
                                       static.passthrough,
                                       static.port_src) },
      { match: rule("ingress",
                    protocol,
                    static.ipv4_src_address,
                    static.ipv4_src_prefix,
                    static.port_src) }
    ].inject(&:merge) => [
      filter.to_hash,
      egress_tables(static.passthrough),
      { priority: 20 + static_priority(static.ipv4_dst_prefix,
                                       static.passthrough,
                                       static.port_dst) },
      { match: rule("egress",
                    protocol,
                    static.ipv4_dst_address,
                    static.ipv4_dst_prefix,
                    static.port_dst) }
    ].inject(&:merge)
  }
end

def filter_hash(filter)
  {
    [ filter.to_hash, ingress_tables(filter.ingress_passthrough), { priority: 10 } ].inject(&:merge) =>
    [ filter.to_hash, egress_tables(filter.egress_passthrough), { priority: 10 } ].inject(&:merge)
  }
end
