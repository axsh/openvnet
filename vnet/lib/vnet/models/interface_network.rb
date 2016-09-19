# -*- coding: utf-8 -*-

module Vnet::Models
  class InterfaceNetwork < Base
    plugin :paranoia_is_deleted

    many_to_one :interface
    many_to_one :network

  end
end
