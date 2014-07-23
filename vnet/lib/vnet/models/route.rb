# -*- coding: utf-8 -*-

module Vnet::Models
  class Route < Base
    taggable 'r'

    plugin :paranoia

    many_to_one :interface
    many_to_one :network
    many_to_one :route_link

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
      ).select_all(:routes).all
    end
  end
end
