# -*- coding: utf-8 -*-

module Vnet::Models
  class Interface < Base
    taggable 'if'
    many_to_one :network

    one_to_many :ip_leases
    one_to_many :network_services
    one_to_many :routes
    one_to_many :mac_leases

    many_to_one :active_datapath, :class => Datapath do |ds|
      Datapath.where({:id => self.active_datapath_id})
    end

    many_to_one :owner_datapath, :class => Datapath do |ds|
      Datapath.where({:id => self.owner_datapath_id})
    end

    subset(:alives, {})

    def mac_addr
      mac_lease = self.mac_leases.first
      mac_lease.nil? || mac_lease.mac_addr
    end

    def ipv4_address
      ip_lease = self.ip_leases.first
      ip_lease.nil? || ip_lease.ip_address.ipv4_address
    end

    def to_hash
      self.values[:ipv4_address] = self.ipv4_address
      super
    end
  end
end
