# -*- coding: utf-8 -*-
Fabricator(:iface, class_name: Vnet::Models::Interface) do
  name 'if-test'
  mode 'virtual'
  active_datapath_id 1
  owner_datapath_id 1
end

Fabricator(:iface_2, class_name: Vnet::Models::Interface) do
  uuid 'if-testuuid'
  name 'if-test2'
  mode 'virtual'
  active_datapath_id 1
  owner_datapath_id 2
end

Fabricator(:eth0, class_name: Vnet::Models::Interface) do
  name 'eth0'
  mode 'physical'
  active_datapath_id 1
  owner_datapath_id 1
end
