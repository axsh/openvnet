# -*- coding: utf-8 -*-

module Vnet::Models

  class TopologySegment < Base
    plugin :paranoia_is_deleted

    many_to_one :segment
    many_to_one :topology

    def validate
      if Vnet::Constants::Topology::MODES_WITH_SEGMENTS.include?(topology.mode).nil?
        errors.add(:topology__mode, 'must be a valid mode')
      end

      super
    end

  end

end
