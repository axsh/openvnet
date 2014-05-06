# -*- coding: utf-8 -*-

Fabricator(:ip_range_group, class_name: Vnet::Models::IpRangeGroup) do
  allocation_type "incremental"
end

Fabricator(:ip_range_group_with_range, class_name: Vnet::Models::IpRangeGroup) do
  allocation_type "incremental"
  ip_ranges(count: 1) { Fabricate(:ip_range_with_range) }
end
