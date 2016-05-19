# -*- coding: utf-8 -*-

module Vnet::Models
  class Segment < Base
    taggable 'seg'
    plugin :paranoia_is_deleted

    one_to_many :datapath_segments

    plugin :association_dependencies,
    # 0010_segment
    datapath_segments: :destroy

  end
end
