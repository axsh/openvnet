# -*- coding: utf-8 -*-

Fabricator(:mac_lease, class_name: Vnet::Models::MacLease) do
  mac_addr { sequence(:mac_addr, 0) }
end
