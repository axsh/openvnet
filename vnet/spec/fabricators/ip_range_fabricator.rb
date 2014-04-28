# -*- coding: utf-8 -*-

Fabricator(:ip_range, class_name: Vnet::Models::IpRange) do
  allocation_type "incremental"
end

Fabricator(:ip_range_with_range, class_name: Vnet::Models::IpRange) do
  allocation_type "incremental"
  ip_range_ranges(count: 1) { Fabricate(:ip_range_range_with_range) }
end
