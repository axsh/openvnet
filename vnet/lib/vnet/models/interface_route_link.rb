# -*- coding: utf-8 -*-

module Vnet::Models
  class InterfaceRouteLink < Base
    plugin :paranoia_is_deleted

    many_to_one :interface
    many_to_one :route_link

  end
end
