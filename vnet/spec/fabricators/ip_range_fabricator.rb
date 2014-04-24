# -*- coding: utf-8 -*-

Fabricator(:ip_range, class_name: Vnet::Models::IpRange) do
  allocation_type "incremental"
end

Fabricator(:ip_range_with_range, class_name: Vnet::Models::IpRange) do
  allocation_type "incremental"
  ip_ranges_ranges(count: 1) { Fabricate(:ip_ranges_range_with_range) }
end
