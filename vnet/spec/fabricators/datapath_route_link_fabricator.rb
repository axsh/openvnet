Fabricator(:datapath_route_link, class_name: Vnet::Models::DatapathRouteLink) do
  id { id_sequence(:datapath_route_link_ids) }

  datapath_id { id_sequence(:datapath_ids) }
  route_link_id { id_sequence(:route_link_ids) }
  interface_id { id_sequence(:interface_ids) }
  ip_lease_id { id_sequence(:ip_lease_ids) }

  mac_address_id { Fabricate(:mac_address).id }
end
