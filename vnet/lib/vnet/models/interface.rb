# -*- coding: utf-8 -*-

module Vnet::Models
  class Interface < Base
    taggable 'if'
    many_to_one :network

    one_to_many :ip_leases
    one_to_many :mac_leases
    one_to_many :network_services
    one_to_many :routes

    many_to_one :owner_datapath, :class => Datapath
    many_to_one :active_datapath, :class => Datapath

    subset(:alives, {})

    def mac_address
      if self.mac_leases.size == 1
        self.mac_leases.first.mac_address
      end
    end

    def all_mac_addresses
      self.mac_leases.map(&:mac_address)
    end

    def ipv4_address
      if self.ip_leases.size == 1
        self.ip_leases.first.ip_address.ipv4_address
      else
        self.ip_leases.map do |il|
          il.ip_address.ipv4_address
        end
      end
    end

    def to_hash
      self.values[:ipv4_address] = self.ipv4_address
      super
    end

  end
end
