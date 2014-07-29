# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class DatapathRouteLink < Base

    plugin :paranoia
    plugin :mac_address

    many_to_one :datapath
    many_to_one :route_link

    many_to_one :interface
    many_to_one :ip_lease

    # TODO: Remove this.
    def datapath_route_links_in_the_same_route_link
      self.class.eager_graph(:datapath).where(route_link_id: self.route_link_id).exclude(datapath_route_links__id: self.id).all
    end

  end

end
