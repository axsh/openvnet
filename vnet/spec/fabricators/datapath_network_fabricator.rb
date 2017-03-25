Fabricator(:datapath_network, class_name: Vnet::Models::DatapathNetwork) do
  id { id_sequence(:datapath_network_ids) }

  datapath_id { id_sequence(:datapath_ids) }
  network_id { id_sequence(:network_ids) }
  interface_id { id_sequence(:interface_ids) }
  ip_lease_id { id_sequence(:ip_lease_ids) }

  mac_address { Pio::Mac.new(id_sequence(:mac_address)) }
end

Fabricator(:datapath_network_1_1, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 1
  network_id 1
  mac_address Pio::Mac.new("52:54:00:00:01:01")
end

Fabricator(:datapath_network_1_2, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 1
  network_id 2
  mac_address Pio::Mac.new("52:54:00:00:01:02")
end

Fabricator(:datapath_network_2_1, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 2
  network_id 1
  mac_address Pio::Mac.new("52:54:00:00:02:01")
end

Fabricator(:datapath_network_2_2, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 2
  network_id 2
  mac_address Pio::Mac.new("52:54:00:00:02:02")
end

Fabricator(:datapath_network_2_3, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 2
  network_id 3
  mac_address Pio::Mac.new("52:54:00:00:02:03")
end

Fabricator(:datapath_network_3_1, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 3
  network_id 1
  mac_address Pio::Mac.new("52:54:00:00:03:01")
end

Fabricator(:datapath_network_3_2, class_name: Vnet::Models::DatapathNetwork) do
  datapath_id 3
  network_id 2
  mac_address Pio::Mac.new("52:54:00:00:03:02")
end
