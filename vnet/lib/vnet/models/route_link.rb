# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class RouteLink < Base
    taggable 'rl'

    plugin :paranoia_is_deleted

    plugin :mac_address

    one_to_one :mac_address

    one_to_many :routes
    one_to_many :datapath_route_links
    many_to_many :datapaths, :join_table => :datapath_route_links, :conditions => "datapath_route_links.deleted_at is null"

    plugin :association_dependencies,
    # 0001_origin
    mac_address: :destroy

  end
end
