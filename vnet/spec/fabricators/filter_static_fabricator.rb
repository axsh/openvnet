Fabricator(:filter_static, class_name: Vnet::Models::FilterStatic) do
end

Fabricator(:static_pass, class_name: Vnet::Models::FilterStatic) do
  ipv4_src_address 0x01010101
  ipv4_dst_address 0
  ipv4_src_prefix 24
  ipv4_dst_prefix 0
  port_src 1
  port_dst 0
  action 'pass'
end

Fabricator(:static_drop, class_name: Vnet::Models::FilterStatic) do
  ipv4_src_address 0x02020202
  ipv4_dst_address 0
  ipv4_src_prefix 24
  ipv4_dst_prefix 0
  port_src 2
  port_dst 0
  action 'drop'
end

Fabricator(:static_pass_without_port, class_name: Vnet::Models::FilterStatic) do
  ipv4_src_address 0x01010101
  ipv4_dst_address 0
  ipv4_src_prefix 24
  ipv4_dst_prefix 0
  action 'pass'
end

Fabricator(:static_drop_without_port, class_name: Vnet::Models::FilterStatic) do
  ipv4_src_address 0x02020202
  ipv4_dst_address 0
  ipv4_src_prefix 24
  ipv4_dst_prefix 0
  action 'drop'
end

