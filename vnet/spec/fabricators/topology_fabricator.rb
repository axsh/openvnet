# -*- coding: utf-8 -*-

Fabricator(:topology, class_name: Vnet::Models::Topology) do
  id { id_sequence(:topology_ids) }
end

Fabricator(:topology_network, class_name: Vnet::Models::TopologyNetwork) do
  id { id_sequence(:topology_network_ids) }
end
