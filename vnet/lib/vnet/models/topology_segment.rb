# -*- coding: utf-8 -*-

module Vnet::Models

  class TopologySegment < Base
    plugin :paranoia_is_deleted

    many_to_one :segment
    many_to_one :topology

  end

end
