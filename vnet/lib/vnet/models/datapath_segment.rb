# -*- coding: utf-8 -*-

module Vnet::Models
  class DatapathSegment < Base
    plugin :paranoia_is_deleted
    plugin :mac_address, segment_name: :mac_address_segment

    many_to_one :datapath
    many_to_one :segment

    many_to_one :interface
    many_to_one :ip_lease

    plugin :association_dependencies,
    # 0001_origin
    _mac_address: :destroy

    # TODO: Remove this.
    def datapath_segments_in_the_same_segment
      self.class.eager_graph(:datapath).where(segment_id: self.segment_id).exclude(datapath_segments__id: self.id).all
    end

  end
end
