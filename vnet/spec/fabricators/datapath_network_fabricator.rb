Fabricator(:datapath_network, class_name: Vnet::Models::DatapathNetwork) do
  id { id_sequence(:datapath_network_ids) }

  datapath_id { id_sequence(:datapath_ids) }
  network_id { id_sequence(:network_ids) }
  interface_id { id_sequence(:interface_ids) }
  ip_lease_id { id_sequence(:ip_lease_ids) }

  mac_address { Pio::Mac.new(id_sequence(:mac_address)) }
end
