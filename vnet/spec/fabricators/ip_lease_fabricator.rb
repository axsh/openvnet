# -*- coding: utf-8 -*-

Fabricator(:ip_lease, class_name: Vnet::Models::IpLease) do
  id { id_sequence(:ip_lease_ids) }

  mac_lease { Fabricate(:mac_lease) }

  network_id { Fabricate(:network).id }
  ip_address_id { |attrs|
    Fabricate(:ip_address_no_nw, network_id: attrs[:network_id]).id
  }
end

Fabricator(:ip_lease_any, class_name: Vnet::Models::IpLease) do
  id { id_sequence(:ip_lease_ids) }
end

Fabricator(:ip_lease_free, class_name: Vnet::Models::IpLease) do
  id { id_sequence(:ip_lease_ids) }

  network_id { Fabricate(:network).id }

  ip_address_id { |attrs|
    Fabricate(:ip_address_no_nw, network_id: attrs[:network_id]).id
  }
end
