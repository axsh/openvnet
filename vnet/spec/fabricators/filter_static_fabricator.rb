Fabricator(:filter_static,
  class_name: Vnet::Models::FilterStatic
)

Fabricator(:static_tcp_pass, class_name: Vnet::Models::FilterStatic) do
  protocol "tcp"
  ipv4_src_address 1
  ipv4_dst_address 1
  port_src 1
  port_dst 1
  ipv4_src_prefix 1
  ipv4_dst_prefix 1
  passthrough true
end

Fabricator(:static_tcp_drop, class_name: Vnet::Models::FilterStatic) do
  protocol "tcp"
  ipv4_src_address 2
  ipv4_dst_address 2
  port_src 2
  port_dst 2
  ipv4_src_prefix 2
  ipv4_dst_prefix 2
  passthrough false
end

Fabricator(:static_udp_pass, class_name: Vnet::Models::FilterStatic) do
  protocol "udp"
  ipv4_src_address 1
  ipv4_dst_address 1
  port_src 1
  port_dst 1
  ipv4_src_prefix 1
  ipv4_dst_prefix 1
  passthrough true
end

Fabricator(:static_udp_drop, class_name: Vnet::Models::FilterStatic) do
  protocol "udp"
  ipv4_src_address 2
  ipv4_dst_address 2
  port_src 2
  port_dst 2
  ipv4_src_prefix 2
  ipv4_dst_prefix 2
  passthrough false
end
