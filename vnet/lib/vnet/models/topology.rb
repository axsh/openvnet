# -*- coding: utf-8 -*-

module Vnet::Models
  class Topology < Base
    taggable 'topo'
    plugin :paranoia_is_deleted

    use_modes Vnet::Constants::Topology::MODES

    one_to_many :topology_datapaths
    one_to_many :topology_networks
    one_to_many :topology_route_links
    one_to_many :topology_segments

    many_to_many :datapaths, :join_table => :topology_datapaths, :conditions => "topology_datapaths.deleted_at is null"
    many_to_many :networks, :join_table => :topology_networks, :conditions => "topology_networks.deleted_at is null"
    many_to_many :segments, :join_table => :topology_segments, :conditions => "topology_segments.deleted_at is null"
    many_to_many :route_links, :join_table => :topology_route_links, :conditions => "topology_route_links.deleted_at is null"

    # TODO: Add many_to_many and one_to_many.

    plugin :association_dependencies,
    # 0009_topology
    topology_datapaths: :destroy,
    topology_networks: :destroy,
    topology_route_links: :destroy,
    topology_segments: :destroy

  end
end
