# -*- coding: utf-8 -*-
Fabricator(:vif, class_name: Vnmgr::Models::Vif) do
  mac_addr "08:00:27:a8:9e:6b".delete(":").hex
  state "attached"
end
