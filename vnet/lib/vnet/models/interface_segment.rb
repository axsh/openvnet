# -*- coding: utf-8 -*-

module Vnet::Models
  class InterfaceSegment < Base
    plugin :paranoia_is_deleted

    many_to_one :interface
    many_to_one :datapath

  end
end
