# -*- coding: utf-8 -*-

module Vnet::Models

  class TopologyNetwork < Base
    plugin :paranoia_is_deleted

    many_to_one :network
    many_to_one :topology

  end

end
