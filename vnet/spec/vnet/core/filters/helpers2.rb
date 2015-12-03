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
        tcp_dst: port_number,
        ip_proto: IPV4_PROTOCOL_TCP
      }
    when "udp" then
      {
        udp_dst: port_number,
        ip_proto: IPV4_PROTOCOL_UDP
      }
    when "icmp" then
      {
        ip_proto: IPV4_PROTOCOL_ICMP
      }
    else      
      return;
    end
end

def rule(traffic_direction, protocol, ipv4_address, prefix, port_number = nil)
  case traffic_direction
  when "ingress" then
    match_ipv4_subnet_src(ipv4_address, prefix).merge(protocol_type(protocol, port_number))
  when "egress" then
    match_ipv4_subnet_dst(ipv4_address, prefix).merge(protocol_type(protocol, port_number))
  else
    return
  end
end

def static_priority(prefix, port = nil, passthrough)
  (prefix << 1) + ((port.nil? || port == 0) ? 0 : 2) + (passthrough ? 1 : 0)
end

def static_hash(static)
  {
    [
      filter.to_hash,
      ingress_tables(static.passthrough),
      { priority: 20 + static_priority(static.ipv4_src_prefix,
                                       static.port_src,
                                       static.passthrough) },
      { match: rule("ingress",
                         static.protocol,
                         static.ipv4_src_address,
                         static.ipv4_src_prefix,
                         static.port_src) }
    ].inject(&:merge) => [
        filter.to_hash,
        egress_tables(static.passthrough),
        { priority: 20 + static_priority(static.ipv4_dst_prefix,
                                         static.port_dst,
                                         static.passthrough) },
        { match: rule("egress",
                           static.protocol,
                           static.ipv4_dst_address,
                           static.ipv4_dst_prefix,
                           static.port_dst) }
      ].inject(&:merge)
  }
end

def static_hash_arp(static)
  {
    [
      filter.to_hash,
      ingress_tables(static.passthrough),
      { priority: 20 + static_priority(static.ipv4_src_prefix,
                                       0,
                                       static.passthrough) },
      { match: {
          eth_type: ETH_TYPE_ARP,
          arp_spa: static.ipv4_src_address,
          arp_spa_mask: IPV4_BROADCAST << (32 - static.ipv4_src_prefix)
        }
      }
    ].inject(&:merge) => [
      filter.to_hash,
      egress_tables(static.passthrough),
      { priority: 20 + static_priority(static.ipv4_dst_prefix,
                                       0,
                                       static.passthrough) },
      { match: {
          eth_type: ETH_TYPE_ARP,
          arp_tpa: static.ipv4_dst_address,
          arp_tpa_mask: IPV4_BROADCAST << (32 - static.ipv4_dst_prefix)
        }
      }
    ].inject(&:merge)
  }
end

def filter_hash(filter)
  {
    [ filter.to_hash, ingress_tables(filter.ingress_passthrough), { priority: 10 } ].inject(&:merge) =>
    [ filter.to_hash, egress_tables(filter.egress_passthrough), { priority: 10 } ].inject(&:merge)
  }
end
