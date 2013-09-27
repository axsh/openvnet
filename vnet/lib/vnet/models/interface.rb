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
      mac_leases.first.try(:mac_address)
    end

    def all_mac_addresses
      mac_leases.map(&:mac_address)
    end

    def ipv4_address
      ip_leases.first.try(:ipv4_address)
    end

    def all_ipv4_addresses
      ip_leases.map(&:ipv4_address)
    end

    def to_hash
      super.merge({
        :ipv4_address => self.ipv4_address,
        :all_ipv4_addresses => self.ipv4_address,
        :mac_address => self.mac_address,
        :all_mac_addresses => self.mac_address,
      })
    end

  end
end
