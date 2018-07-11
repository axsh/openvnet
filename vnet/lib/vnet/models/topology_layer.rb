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

    def validate
      if Vnet::Constants::Topology::MODES_WITH_OVERLAYS.include?(overlay.mode).nil?
        errors.add(:overlay__mode, 'must be a valid mode')
      end

      if Vnet::Constants::Topology::MODES_WITH_UNDERLAYS.include?(underlay.mode).nil?
        errors.add(:underlay__mode, 'must be a valid mode')
      end

      super
    end

  end
end
