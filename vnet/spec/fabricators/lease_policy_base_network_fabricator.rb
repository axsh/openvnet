# -*- coding: utf-8 -*-

Fabricator(:lease_policy_base_network, class_name: Vnet::Models::LeasePolicyBaseNetwork) do
end

Fabricator(:lease_policy_base_network_with_network, class_name: Vnet::Models::LeasePolicyBaseNetwork) do
  network { Fabricate(:network_for_range) }
  ip_range_group { Fabricate(:ip_range_group_with_range) }
end
