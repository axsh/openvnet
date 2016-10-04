# -*- coding: utf-8 -*-

ID_SEQUENCES = [
  :active_interface_ids,
  :interface_ids,
  :interface_port_ids,
  :ip_lease_ids,
  :mac_lease_ids,
]

def id_sequence(id_type)
  if ID_SEQUENCES.index(id_type).nil?
    throw "Could not find id_sequence type '#{id_type.inspect}'"
  end

  sequence(id_type, (ID_SEQUENCES.index(id_type) + 1) * 1000000)
end
