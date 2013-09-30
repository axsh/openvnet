# -*- coding: utf-8 -*-
Fabricator(:interface, class_name: Vnet::Models::Interface) do
  uuid { "vif-uuid#{sequence(:vif_uuid, 0)}" }
  #mac_addr "08:00:27:a8:9e:6b".delete(":").hex
  mac_address { sequence(:mac_address, 0) }
end
