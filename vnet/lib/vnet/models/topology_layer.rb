# -*- coding: utf-8 -*-

module Vnet::Models

  class TopologyLayer < Base
    plugin :paranoia_is_deleted

    many_to_one :overlay, :class => Topology
    many_to_one :underlay, :class => Topology
  end

end
