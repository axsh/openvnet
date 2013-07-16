# -*- coding: utf-8 -*-
Fabricator(:vif, class_name: Vnet::Models::Vif) do
  #mac_addr "08:00:27:a8:9e:6b".delete(":").hex
  mac_addr { sequence(:mac_addr, 0) }
  state "attached"
end
