# -*- coding: utf-8 -*-

Fabricator(:topology, class_name: Vnet::Models::Topology) do
  id { id_sequence(:topology_ids) }
end
