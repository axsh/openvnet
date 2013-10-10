# -*- coding: utf-8 -*-

module Vnet::Models
  class RouteLink < Base
    taggable 'rl'

    plugin :mac_address
    one_to_many :routes
    one_to_many :datapath_route_links
    many_to_many :datapaths, :join_table => :datapath_route_links

    subset(:alives, {})
  end
end
