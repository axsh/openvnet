Fabricator(:datapath_network, class_name: Vnet::Models::DatapathNetwork) do
  id { id_sequence(:datapath_network_ids) }

  datapath_id { id_sequence(:datapath_ids) }
  network_id { id_sequence(:network_ids) }
  interface_id { id_sequence(:interface_ids) }
  ip_lease_id { id_sequence(:ip_lease_ids) }

  mac_address_id { |attr|
    if attr[:mac]
      Fabricate(:mac_address, mac_address: attr[:mac]).id
    else
      Fabricate(:mac_address).id
    end
  }
end
