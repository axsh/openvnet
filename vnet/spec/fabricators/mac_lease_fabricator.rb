# -*- coding: utf-8 -*-

Fabricator(:mac_lease, class_name: Vnet::Models::MacLease) do
  interface { Fabricate(:interface) }
  mac_address { sequence(:mac_address, 0) }
end

Fabricator(:mac_lease_no_seg, class_name: Vnet::Models::MacLease) do
  interface { Fabricate(:interface) }
  mac_address { sequence(:mac_address, 0) }
end

Fabricator(:mac_lease_any, class_name: Vnet::Models::MacLease) do
end

Fabricator(:mac_lease_free, class_name: Vnet::Models::MacLease) do
  mac_address { sequence(:mac_address, 0) }
end
