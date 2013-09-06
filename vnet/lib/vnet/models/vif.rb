# -*- coding: utf-8 -*-

module Vnet::Models
  class Vif < Base
    taggable 'vif'
    many_to_one :network

    one_to_many :ip_leases
    one_to_many :network_services
    one_to_many :routes

    subset(:alives, {})

    def ipv4_address
      ip_lease = self.ip_leases.first
      ip_lease.nil? || ip_lease.ip_address.ipv4_address
    end

  end
end
