# -*- coding: utf-8 -*-
Fabricator(:ip_lease, class_name: Vnet::Models::IpLease) do
  mac_lease { Fabricate(:mac_lease) }
  network_id { Fabricate(:network).id }
  ipv4_address { sequence(:ipv4_address, 1) }
end

Fabricator(:ip_lease_any, class_name: Vnet::Models::IpLease) do
end
