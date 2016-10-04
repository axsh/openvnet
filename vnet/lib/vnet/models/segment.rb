# -*- coding: utf-8 -*-

module Vnet::Models
  class Segment < Base
    taggable 'seg'
    plugin :paranoia_is_deleted

    use_modes Vnet::Constants::Segment::MODES

    one_to_many :networks

    one_to_many :datapath_segments
    one_to_many :interface_segments

    plugin :association_dependencies,
    # 0010_segment
    datapath_segments: :destroy,
    networks: :destroy,
    # 0011_assoc_interface
    interface_segments: :destroy

  end
end
