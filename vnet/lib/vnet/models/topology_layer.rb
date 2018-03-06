# -*- coding: utf-8 -*-

module Vnet::Models
  class TopologyLayer < Base
    plugin :paranoia_is_deleted

    many_to_one :overlay, :class => Topology
    many_to_one :underlay, :class => Topology

    one_to_many :datapath_networks
    one_to_many :datapath_segments
    one_to_many :datapath_route_links

    plugin :association_dependencies,
    # 0018_topology_lease
    datapath_networks: :destroy,
    datapath_segments: :destroy,
    datapath_route_links: :destroy

  end
end
