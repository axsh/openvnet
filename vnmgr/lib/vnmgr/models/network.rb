# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Network < Base
    taggable 'nw'

    one_to_many :routers
    one_to_many :dhcp_ranges
    one_to_many :tunnels
    one_to_many :vifs
    one_to_many :ip_leases

    many_to_one :dc_network
  end
end
