Fabricator(:filter_static,
  class_name: Vnet::Models::FilterStatic
)

Fabricator(:static_enable_tcp, class_name: Vnet::Models::FilterStatic) do
  protocol "tcp",
  ipv4_src_address IPAddr.new("10.101.0.11").to_i,
  ipv4_dst_address IPAddr.new("10.101.0.11").to_i,
  port_src_first 80,
  port_src_last 80,
  port_dst_first  80,
  port_dst_last 80,
  ipv4_src_prefix 32, 
  ipv4_dst_prefix 32,
  passthrough true
end

Fabricator(:static_enable_udp, class_name: Vnet::Models::FilterStatic) do
  protocol "upd",
  ipv4_src_address IPAddr.new("10.101.0.11").to_i,
  ipv4_dst_address IPAddr.new("10.101.0.11").to_i,
  port_src_first 80,
  port_src_last 80,
  port_dst_first  80,
  port_dst_last 80,
  ipv4_src_prefix 32, 
  ipv4_dst_prefix 32,
  passthrough true
end
