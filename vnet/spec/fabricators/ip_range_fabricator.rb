# -*- coding: utf-8 -*-

Fabricator(:ip_range, class_name: Vnet::Models::IpRange) do
  allocation_type "incremental"
end
