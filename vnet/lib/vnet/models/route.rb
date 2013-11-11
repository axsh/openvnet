# -*- coding: utf-8 -*-

module Vnet::Models
  class Route < Base
    taggable 'r'

    many_to_one :interface
    many_to_one :network
    many_to_one :route_link

    subset(:alives, {})

    #one_to_many :on_other_networks, :class => Route do |ds|
    #  ds = Route.join(:interfaces, :routes__interface_id => :interfaces__id)
    #  ds = ds.where(~{:interfaces__network_id => self.interface.network_id})
    #  ds.select_all(:routes)
    #end

    def on_other_networks(network_id)
      Route.dataset.join_table(
        :inner, :interfaces,
        {interfaces__id: :routes__interface_id}
      ).join_table(
        :left, :ip_leases,
        {ip_leases__interface_id: :interfaces__id}
      ).join_table(
        :inner, :ip_addresses,
        {ip_addresses__id: :ip_leases__ip_address_id} & {ip_addresses__network_id: network_id}
      ).where(
        ~{routes__id: self.id}
      ).select_all(:routes).alives.all
    end
  end
end
