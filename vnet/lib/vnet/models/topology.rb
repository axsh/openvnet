# -*- coding: utf-8 -*-

module Vnet::Models
  class Topology < Base
    taggable 'topo'
    plugin :paranoia_is_deleted

    use_modes Vnet::Constants::Topology::MODES

    one_to_many :topology_datapaths
    one_to_many :topology_mac_range_groups
    one_to_many :topology_networks
    one_to_many :topology_route_links
    one_to_many :topology_segments

    one_to_many :datapath_networks
    one_to_many :datapath_segments
    one_to_many :datapath_route_links

    many_to_many :datapaths, :join_table => :topology_datapaths, :conditions => "topology_datapaths.deleted_at is null"
    many_to_many :mac_range_groups, :join_table => :topology_mac_range_groups, :conditions => "topology_mac_range_groups.deleted_at is null"
    many_to_many :networks, :join_table => :topology_networks, :conditions => "topology_networks.deleted_at is null"
    many_to_many :segments, :join_table => :topology_segments, :conditions => "topology_segments.deleted_at is null"
    many_to_many :route_links, :join_table => :topology_route_links, :conditions => "topology_route_links.deleted_at is null"

    many_to_many :overlays, :class => Topology, :join_table => :topology_layers, :left_key => :underlay_id, :conditions => "topology_layers.deleted_at is null"
    many_to_many :underlays, :class => Topology, :join_table => :topology_layers, :left_key => :overlay_id, :conditions => "topology_layers.deleted_at is null"

    plugin :association_dependencies,
    # 0009_topology
    topology_datapaths: :destroy,
    topology_networks: :destroy,
    topology_route_links: :destroy,
    topology_segments: :destroy,
    # 0018_topology_lease
    datapath_networks: :destroy,
    datapath_segments: :destroy,
    datapath_route_links: :destroy,
    topology_mac_range_groups: :destroy

  end
end
