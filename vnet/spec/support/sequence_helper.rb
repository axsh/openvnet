# -*- coding: utf-8 -*-

ID_SEQUENCES = [
  :active_interface_ids,
  :datapath_ids,
  :datapath_network_ids,
  :datapath_segment_ids,
  :datapath_route_link_ids,
  :filter_ids,
  :interface_ids,
  :interface_network_ids,
  :interface_route_link_ids,
  :interface_segment_ids,
  :interface_port_ids,
  :ip_address_ids,
  :ip_lease_ids,
  :ip_retention,
  :ip_retention_container,
  :network_ids,
  :mac_address,
  :mac_address_ids,
  :mac_lease_ids,
  :mac_range_ids,
  :mac_range_group_ids,
  :network_ids,
  :route_ids,
  :route_link_ids,
  :segment_ids,
  :topology_ids,
  :topology_datapath_ids,
  :topology_mac_range_group_ids,
  :topology_network_ids,
  :topology_segment_ids,
  :topology_route_link_ids,
  :topology_underlay_ids,
  :translation_ids,
  :translation_static_address_ids,
]

def id_sequence(id_type)
  if ID_SEQUENCES.index(id_type).nil?
    throw "Could not find id_sequence type '#{id_type.inspect}'"
  end

  sequence(id_type, (ID_SEQUENCES.index(id_type) + 1) * 1000000 + 1)
end
