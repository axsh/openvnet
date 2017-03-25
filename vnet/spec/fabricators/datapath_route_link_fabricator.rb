Fabricator(:datapath_route_link, class_name: Vnet::Models::DatapathRouteLink) do
  id { id_sequence(:datapath_route_link_ids) }

  datapath_id { id_sequence(:datapath_ids) }
  route_link_id { id_sequence(:route_link_ids) }
  interface_id { id_sequence(:interface_ids) }
  ip_lease_id { id_sequence(:ip_lease_ids) }

  mac_address { Pio::Mac.new(id_sequence(:mac_address)) }
end

Fabricator(:datapath_route_link_1_1, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 1
  route_link_id 1
  mac_address Pio::Mac.new("52:54:00:01:01:01")
end

Fabricator(:datapath_route_link_1_2, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 1
  route_link_id 2
  mac_address Pio::Mac.new("52:54:00:01:01:02")
end

Fabricator(:datapath_route_link_2_1, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 2
  route_link_id 1
  mac_address Pio::Mac.new("52:54:00:01:02:01")
end

Fabricator(:datapath_route_link_2_2, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 2
  route_link_id 2
  mac_address Pio::Mac.new("52:54:00:01:02:02")
end

Fabricator(:datapath_route_link_2_3, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 2
  route_link_id 3
  mac_address Pio::Mac.new("52:54:00:01:02:03")
end

Fabricator(:datapath_route_link_3_1, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 3
  route_link_id 1
  mac_address Pio::Mac.new("52:54:00:01:03:01")
end

Fabricator(:datapath_route_link_3_2, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 3
  route_link_id 2
  mac_address Pio::Mac.new("52:54:00:01:03:02")
end
