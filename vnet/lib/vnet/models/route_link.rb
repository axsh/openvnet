# -*- coding: utf-8 -*-

module Vnet::Models
  class RouteLink < Base
    taggable 'rl'

    plugin :paranoia_is_deleted
    plugin :mac_address_no_segment

    one_to_many :routes

    one_to_many :interface_route_links
    one_to_many :topology_route_links

    one_to_many :datapath_route_links
    many_to_many :datapaths, join_table: :datapath_route_links, conditions: "datapath_route_links.deleted_at is null"

    one_to_many :translation_static_addresses
    many_to_many :translations, join_table: :translation_static_addresses, conditions: "translation_static_addresses.deleted_at is null"

    plugin :association_dependencies,
    # 0001_origin
    datapath_route_links: :destroy,
    routes: :destroy,
    translation_static_addresses: :destroy,
    _mac_address: :destroy,
    # 0009_topology
    topology_route_links: :destroy,
    # 0011_assoc_interface
    interface_route_links: :destroy

  end
end
