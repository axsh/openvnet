# -*- coding: utf-8 -*-

module Vnet::Models
  class Interface < Base
    taggable 'if'

    one_to_many :ip_leases
    one_to_many :ip_addresses, :join_table => :ip_leases
    one_to_many :networks, :join_table => :ip_addresses
    one_to_many :mac_leases
    one_to_many :network_services
    one_to_many :routes
    one_to_many :mac_leases

    many_to_one :owner_datapath, :class => Datapath
    many_to_one :active_datapath, :class => Datapath

    many_to_many :security_groups, :join_table => :interface_security_groups

    plugin :association_dependencies,
      :ip_leases => :destroy,
      :mac_leases => :destroy,
      :network_services => :destroy,
      :routes => :destroy

    subset(:alives, {})

    def network
      ip_leases.first.try(:network)
    end

    def ipv4_address
      ip_leases.first.try(:ipv4_address)
    end

    def mac_address
      mac_leases.first.try(:mac_address)
    end

    def to_hash
      super.merge({
        :ipv4_address => self.ipv4_address,
        :mac_address => self.mac_address,
      })
    end
  end
end
