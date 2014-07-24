# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class DatapathRouteLink < Base

    plugin :paranoia_with_unique_constraint
    plugin :mac_address

    many_to_one :datapath
    many_to_one :route_link

    many_to_one :interface
    many_to_one :ip_lease

  end
end
