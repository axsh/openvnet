# -*- coding: utf-8 -*-
Fabricator(:iface, class_name: Vnet::Models::Interface) do
  #mac_addr "08:00:27:a8:9e:6b".delete(":").hex
  #mac_addr { sequence(:mac_addr, 0) }
  name 'vif-test'
  mode 'virtual'
  active_datapath_id 1
  owner_datapath_id 2
end
