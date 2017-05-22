# -*- coding: utf-8 -*-

# TODO: Deprecate.
Fabricator(:mac_lease, class_name: Vnet::Models::MacLease) do
  id { id_sequence(:mac_lease_ids) }

  interface { Fabricate(:interface) }
  mac_address { sequence(:mac_address, 0) }
end

Fabricator(:mac_lease_no_seg, class_name: Vnet::Models::MacLease) do
  id { id_sequence(:mac_lease_ids) }

  interface { Fabricate(:interface) }
  mac_address { sequence(:mac_address, 0) }
end

Fabricator(:mac_lease_any, class_name: Vnet::Models::MacLease) do
  id { id_sequence(:mac_lease_ids) }
end

Fabricator(:mac_lease_free, class_name: Vnet::Models::MacLease) do
  id { id_sequence(:mac_lease_ids) }

  mac_address { sequence(:mac_address, 0) }
end

Fabricator(:mac_lease_with_segment, class_name: Vnet::Models::MacLease) do
  id { id_sequence(:mac_lease_ids) }

  segment_id { Fabricate(:segment).id }
  mac_address_id { |attrs|
    Fabricate(:mac_address, segment_id: attrs[:segment_id]).id
  }
end
