# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Network < Base
    taggable 'nw'

    one_to_many :Router
    one_to_many :DhcpRange
    one_to_many :Tunnel
    one_to_many :vifs
    one_to_many :IpLease

    many_to_one :dc_network
  end
end
