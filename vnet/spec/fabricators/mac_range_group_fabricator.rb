# -*- coding: utf-8 -*-

Fabricator(:mac_range_group, class_name: Vnet::Models::MacRangeGroup) do
  allocation_type "random"
end

Fabricator(:mac_range_group_with_range, class_name: Vnet::Models::MacRangeGroup) do
  allocation_type "random"
  mac_ranges(count: 1) { Fabricate(:mac_range_with_range) }
end

Fabricator(:mac_range_group_with_range2, class_name: Vnet::Models::MacRangeGroup) do
  allocation_type "random"
  mac_ranges(count: 1) { Fabricate(:mac_range_with_range2) }
end
