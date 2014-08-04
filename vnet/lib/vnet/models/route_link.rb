# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class RouteLink < Base
    taggable 'rl'

    plugin :paranoia

    plugin :mac_address
    one_to_many :routes
    one_to_many :datapath_route_links
    many_to_many :datapaths, :join_table => :datapath_route_links, :conditions => "datapath_route_links.deleted_at is null"

  end
end
