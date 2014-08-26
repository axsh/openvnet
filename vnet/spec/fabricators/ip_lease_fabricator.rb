# -*- coding: utf-8 -*-
Fabricator(:ip_lease, class_name: Vnet::Models::IpLease) do
  mac_lease { Fabricate(:mac_lease) }
  network_id { Fabricate(:network).id }

  # ipv4_address { sequence(:ipv4_address, 1) }
  ip_address_id { |attrs|
    Fabricate(:ip_address_no_nw, network_id: attrs[:network_id]).id
  }
end

Fabricator(:ip_lease_any, class_name: Vnet::Models::IpLease) do
end
