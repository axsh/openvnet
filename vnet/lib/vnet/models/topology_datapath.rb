# -*- coding: utf-8 -*-

module Vnet::Models

  class TopologyDatapath < Base
    plugin :paranoia_is_deleted

    many_to_one :topology
    many_to_one :datapath

    def validate
      if Vnet::Constants::Topology::MODES_WITH_DATAPATHS.include?(topology.mode).nil?
        errors.add(:topology__mode, 'must be a valid mode')
      end

      super
    end

  end

end
