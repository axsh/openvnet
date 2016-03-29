# -*- coding: utf-8 -*-

module Vnet::Models
  class RouteLink < Base
    taggable 'rl'

    plugin :paranoia_is_deleted
    plugin :mac_address

    one_to_many :routes

    one_to_many :datapath_route_links
    many_to_many :datapaths, join_table: :datapath_route_links, conditions: "datapath_route_links.deleted_at is null"

    one_to_many :translation_static_addresses
    many_to_many :translations, join_table: :translation_static_addresses, conditions: "translation_static_addresses.deleted_at is null"

    plugin :association_dependencies,
    # 0001_origin
    datapath_route_links: :destroy,
    routes: :destroy,
    translation_static_addresses: :destroy,
    _mac_address: :destroy

    def self.lookup_by_nw(i_uuid, e_uuid)
      i = lookup_nw(i_uuid)
      e = lookup_nw(e_uuid)
      i & e
    end

    private

    def self.lookup_nw(uuid)
      RouteLink.dataset.join_table(
        :inner,
        :routes,
        route_links__id: :routes__route_link_id
      ).join_table(
        :inner,
        :networks,
        routes__network_id: :networks__id
      ).where(:networks__uuid => uuid.gsub("nw-","")).select(:route_links__uuid).all.map(&:canonical_uuid)
    end
  end
end
