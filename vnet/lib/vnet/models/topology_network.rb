# -*- coding: utf-8 -*-

module Vnet::Models

  class TopologyNetwork < Base
    plugin :paranoia_is_deleted

    many_to_one :network
    many_to_one :topology

    def validate
      if Vnet::Constants::Topology::MODES_WITH_NETWORKS.include?(topology.mode).nil?
        errors.add(:topology__mode, 'must be a valid mode')
      end

      super
    end

  end

end
