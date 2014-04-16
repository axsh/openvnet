# -*- coding: utf-8 -*-

Fabricator(:lease_policy, class_name: Vnet::Models::LeasePolicy) do
  mode "simple"
  timing "immediate"
end
