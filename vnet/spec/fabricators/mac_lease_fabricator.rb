# -*- coding: utf-8 -*-

Fabricator(:mac_lease, class_name: Vnet::Models::MacLease) do
  mac_address { sequence(:mac_address, 0) }
end
