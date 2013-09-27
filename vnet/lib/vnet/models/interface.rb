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

    def ipv4_address
      ip_leases.first.try(:ipv4_address)
    end

    def to_hash
      super.merge({
        :ipv4_address => self.ipv4_address,
      })
    end

  end
end
