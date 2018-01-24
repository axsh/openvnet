# -*- coding: utf-8 -*-

module Vnet::Models

  class TopologyMacRangeGroup < Base
    plugin :paranoia_is_deleted

    many_to_one :topology
    many_to_one :mac_range_group

  end

end
