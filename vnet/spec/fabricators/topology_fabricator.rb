# -*- coding: utf-8 -*-

Fabricator(:topology, class_name: Vnet::Models::Topology) do
  id { id_sequence(:topology_ids) }
end

Fabricator(:topology_datapath, class_name: Vnet::Models::TopologyDatapath) do
  id { id_sequence(:topology_datapath_ids) }
end

Fabricator(:topology_mac_range_group, class_name: Vnet::Models::TopologyMacRangeGroup) do
  id { id_sequence(:topology_mac_range_group_ids) }
end

Fabricator(:topology_network, class_name: Vnet::Models::TopologyNetwork) do
  id { id_sequence(:topology_network_ids) }
end

Fabricator(:topology_segment, class_name: Vnet::Models::TopologySegment) do
  id { id_sequence(:topology_segment_ids) }
end

Fabricator(:topology_route_link, class_name: Vnet::Models::TopologyRouteLink) do
  id { id_sequence(:topology_route_link_ids) }
end

Fabricator(:topology_underlay, class_name: Vnet::Models::TopologyLayer) do
  id { id_sequence(:topology_underlay_ids) }
end
