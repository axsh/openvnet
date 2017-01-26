# -*- coding: utf-8 -*-

module Vnet::Models

  class ActiveRouteLink < Base

    plugin :paranoia_is_deleted

    many_to_one :route_link
    many_to_one :datapath

  end

end
