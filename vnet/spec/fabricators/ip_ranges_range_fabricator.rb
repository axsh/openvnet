# -*- coding: utf-8 -*-

Fabricator(:ip_ranges_range, class_name: Vnet::Models::IpRangesRange) do
end

Fabricator(:ip_ranges_range_with_range, class_name: Vnet::Models::IpRangesRange) do
  begin_ipv4_address IPAddr.new("10.102.0.100").to_i
  end_ipv4_address IPAddr.new("10.102.0.102").to_i
end
