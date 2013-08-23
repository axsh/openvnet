# -*- coding: utf-8 -*-

module Vnet::Models
  class RouteLink < Base
    taggable 'rl'

    one_to_many :routes
    one_to_many :datapath_route_links

    subset(:alives, {})

  end
end
