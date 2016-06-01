# -*- coding: utf-8 -*-

module Vnet::Models
  class DatapathRouteLink < Base

    plugin :paranoia_is_deleted
    plugin :mac_address_old

    many_to_one :datapath
    many_to_one :route_link

    many_to_one :interface
    many_to_one :ip_lease

    plugin :association_dependencies,
    # 0001_origin
    _mac_address: :destroy

    # TODO: Remove this.
    def datapath_route_links_in_the_same_route_link
      self.class.eager_graph(:datapath).where(route_link_id: self.route_link_id).exclude(datapath_route_links__id: self.id).all
    end

  end
end
