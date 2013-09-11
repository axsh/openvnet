Fabricator(:datapath_network_1_1, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 1
  network_id 1
  broadcast_mac_address Trema::Mac.new("52:54:00:00:00:01").value
  is_connected false
end

Fabricator(:datapath_network_1_2, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 1
  network_id 2
  broadcast_mac_address Trema::Mac.new("52:54:00:00:00:02").value
  is_connected false
end

Fabricator(:datapath_network_2_1, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 2
  network_id 1
  broadcast_mac_address Trema::Mac.new("52:54:00:00:00:03").value
  is_connected false
end

Fabricator(:datapath_network_2_2, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 2
  network_id 2
  broadcast_mac_address Trema::Mac.new("52:54:00:00:00:04").value
  is_connected false
end

Fabricator(:datapath_network_2_3, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 2
  network_id 3
  broadcast_mac_address Trema::Mac.new("52:54:00:00:00:05").value
  is_connected false
end
