# -*- coding: utf-8 -*-

ID_SEQUENCES = [
  :active_interface_ids,
  :interface_ids,
  :interface_port_ids,
  :ip_lease_ids,
  :ip_retention,
  :ip_retention_container,
  :mac_lease_ids,
  :topology_ids,
  :topology_datapath_ids,
  :topology_network_ids,
  :topology_segment_ids,
  :topology_route_link_ids,
  :topology_underlay_ids
]

def id_sequence(id_type)
  if ID_SEQUENCES.index(id_type).nil?
    throw "Could not find id_sequence type '#{id_type.inspect}'"
  end

  sequence(id_type, (ID_SEQUENCES.index(id_type) + 1) * 1000000 + 1)
end
