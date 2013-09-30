# -*- coding: utf-8 -*-

module Vnet::Models
  class Interface < Base
    taggable 'vif'
    many_to_one :network

    one_to_many :ip_leases
    one_to_many :network_services
    one_to_many :routes
    one_to_many :mac_leases

    many_to_one :owner_datapath, :class => Datapath
    many_to_one :active_datapath, :class => Datapath

    subset(:alives, {})

    def all_mac_addresses
      self.mac_leases.map do |ml|
        ml.mac_address
      end
    end

    def ipv4_address
      ip_lease = self.ip_leases.first
      ip_lease && ip_lease.ip_address.ipv4_address
    end

    def to_hash
      self.values[:ipv4_address] = self.ipv4_address
      super
    end

  end
end
