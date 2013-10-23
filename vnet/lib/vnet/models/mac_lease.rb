# -*- coding: utf-8 -*-

module Vnet::Models
  class MacLease < Base
    taggable 'ml'

    plugin :paranoia
    plugin :mac_address

    many_to_one :interface
    one_to_many :ip_leases
    plugin :association_dependencies, :ip_leases => :destroy

    def to_hash
      super.merge({
        :mac_address => self.mac_address
      })
    end
  end
end
