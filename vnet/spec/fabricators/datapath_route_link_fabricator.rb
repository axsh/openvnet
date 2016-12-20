Fabricator(:datapath_route_link, class_name: Vnet::Models::DatapathRouteLink) do
end

Fabricator(:datapath_route_link_1_1, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 1
  route_link_id 1
  mac_address Pio::Mac.new("52:54:00:01:01:01")
  is_connected false
end

Fabricator(:datapath_route_link_1_2, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 1
  route_link_id 2
  mac_address Pio::Mac.new("52:54:00:01:01:02")
  is_connected false
end

Fabricator(:datapath_route_link_2_1, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 2
  route_link_id 1
  mac_address Pio::Mac.new("52:54:00:01:02:01")
  is_connected false
end

Fabricator(:datapath_route_link_2_2, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 2
  route_link_id 2
  mac_address Pio::Mac.new("52:54:00:01:02:02")
  is_connected false
end

Fabricator(:datapath_route_link_2_3, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 2
  route_link_id 3
  mac_address Pio::Mac.new("52:54:00:01:02:03")
  is_connected false
end

Fabricator(:datapath_route_link_3_1, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 3
  route_link_id 1
  mac_address Pio::Mac.new("52:54:00:01:03:01")
  is_connected false
end

Fabricator(:datapath_route_link_3_2, class_name: Vnet::Models::DatapathRouteLink) do
  datapath_id 3
  route_link_id 2
  mac_address Pio::Mac.new("52:54:00:01:03:02")
  is_connected false
end
