# -*- coding: utf-8 -*-

Fabricator(:ip_range, class_name: Vnet::Models::IpRange) do
end

Fabricator(:ip_range_with_range, class_name: Vnet::Models::IpRange) do
  begin_ipv4_address IPAddr.new("10.102.0.101").to_i
  end_ipv4_address IPAddr.new("10.102.0.110").to_i
end
