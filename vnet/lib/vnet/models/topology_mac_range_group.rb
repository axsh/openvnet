# -*- coding: utf-8 -*-

module Vnet::Models
  class TopologyMacRangeGroup < Base
    plugin :paranoia_is_deleted

    many_to_one :topology
    many_to_one :mac_range_group

    one_to_many :datapath_networks
    one_to_many :datapath_segments
    one_to_many :datapath_route_links

    plugin :association_dependencies,
    # 0018_topology_lease
    datapath_networks: :destroy,
    datapath_segments: :destroy,
    datapath_route_links: :destroy

    def validate
      if Vnet::Constants::Topology::MODES_WITH_MAC_RANGE_GROUPS.include?(topology.mode).nil?
        errors.add(:topology__modes, 'must be a valid mode')
      end

      super
    end

  end
end
