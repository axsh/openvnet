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
    when IPV4_PROTOCOL_TCP then
      {
        tcp_dst: port_number,
        ip_proto: protocol
      }
    when IPV4_PROTOCOL_UDP then
      {
        udp_dst: port_number,
        ip_proto: protocol
      }
    end
end

def rule_flow(traffic_direction, protocol, ipv4_address, prefix, port_number)
  case traffic_direction
  when "ingress" then
    match_ipv4_subnet_src(ipv4_address, prefix).merge(protocol_type(protocol, port_number))
  when "egress" then
    match_ipv4_subnet_dst(ipv4_address, prefix).merge(protocol_type(protocol, port_number))
  else
    return
  end
end

def static_filter_hash(filter_static)
  {
    [
      filter.to_hash,
      ingress_tables(filter_static.passthrough),
      { priority: 20 + static_priority(filter_static.ipv4_src_prefix,
                                       filter_static.passthrough,
                                       filter_static.port_src_first) },
      { match: rule_flow("ingress", IPV4_PROTOCOL_TCP,
                         filter_static.port_src_first,
                         filter_static.ipv4_src_address,
                         filter_static.ipv4_src_prefix) }
    ].inject(:merge) =>　[
        filter.to_hash,
        egress_tables(filter_static.passthrough),
        { priority: 20 + static_priority(filter_static.ipv4_dst_prefix,
                                         filter_static.passthrough,
                                         filter_static.port_dst_first) },
        { match: rule_flow("egress", IPV4_PROTOCOL_TCP,
                           filter_static.port_dst_first,
                           filter_static.ipv4_dst_address,
                           filter_static.ipv4_dst_prefix) }
      ].inject(:merge)
  }
end

def filter_hash(filter)
  {
    [ filter.to_hash, ingress_tables(filter.ingress_passthrough), { priority: 10 } ].inject(&:merge) =>
    [ filter.to_hash, egress_tables(filter.egress_passthrough), { priority: 10 } ].inject(&:merge)
  }
end

def static_priority(prefix, port, passthrough)
  (prefix << 1) + ((port.nil? || port == 0) ? 0 : 2) + (passthrough ? 1 : 0)
end
