# -*- coding: utf-8 -*-

module Vnet::Models
  class Interface < Base
    taggable 'vif'
    many_to_one :network

    one_to_many :ip_leases
    one_to_many :network_services
    one_to_many :routes

    many_to_one :owner_datapath, :class => Datapath
    many_to_one :active_datapath, :class => Datapath

    many_to_many :security_groups, :join_table => :interface_security_groups

    subset(:alives, {})

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
