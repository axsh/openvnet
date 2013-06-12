# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Vif < Base
    taggable 'vif'
    many_to_one :network
    many_to_one :network_service
    one_to_many :ip_leases

    def ipv4_address
      ip_lease = self.ip_leases.first
      ip_lease.nil? || ip_lease.ip_address.ipv4_address
    end
  end
end
