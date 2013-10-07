# -*- coding: utf-8 -*-
Fabricator(:ip_lease, class_name: Vnet::Models::IpLease) do
  interface { Fabricate(:interface) }
  network_uuid { Fabricate(:network).canonical_uuid }
  ipv4_address { sequence(:ipv4_address, 1) }
end

Fabricator(:ip_lease_any, class_name: Vnet::Models::IpLease) do
end
