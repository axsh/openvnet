# -*- coding: utf-8 -*-

module Vnet::Models
  class RouteLink < Base
    taggable 'rl'

    one_to_many :routes
    one_to_many :datapath_route_links
    one_to_one :mac_address

    subset(:alives, {})

    def mac_addr
      self.mac_address.mac_address
    end
  end
end
