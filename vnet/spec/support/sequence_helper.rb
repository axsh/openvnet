# -*- coding: utf-8 -*-

ID_SEQUENCES = {
  interface_ids: 1 * 100000
}

def id_sequence(id_type)
  if ID_SEQUENCES[id_type].nil?
    throw "Could not find id_sequence type '#{id_type.inspect}'"
  end

  sequence(id_type, ID_SEQUENCES[id_type])
end
