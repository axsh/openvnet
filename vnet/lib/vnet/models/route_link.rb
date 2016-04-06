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
      i = where_network_uuid(i_uuid)
      e = where_network_uuid(e_uuid)
      self[:uuid => (i&e).first]
    end

    dataset_module do
      def join_routes_networks
        self.join_table(:inner, :networks, routes__network_id: :networks__id)
      end

      def join_routes
        self.join_table(:inner, :routes, route_links__id: :routes__route_link_id)
      end

      def where_network_uuid(uuid)
        self.join_routes.join_routes_networks.where(:networks__uuid => uuid.gsub("nw-","")).select(:route_links__uuid).all.map(&:uuid)
      end
    end
  end
end
