Fabricator(:datapath_segment, class_name: Vnet::Models::DatapathSegment) do
  id { id_sequence(:datapath_segment_ids) }

  datapath_id { id_sequence(:datapath_ids) }
  segment_id { id_sequence(:segment_ids) }
  interface_id { id_sequence(:interface_ids) }
  ip_lease_id { id_sequence(:ip_lease_ids) }

  mac_address { Pio::Mac.new(id_sequence(:mac_address)) }
end
