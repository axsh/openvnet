# -*- coding: utf-8 -*-

module Vnet::Models
  class Network < Base
    taggable 'nw'

    one_to_many :datapath_networks
    one_to_many :dhcp_ranges
    one_to_many :ip_addresses
    one_to_many :tunnels

    #many_to_many :network_services, :join_table => :interfaces, :right_key => :id, :right_primary_key => :interface_id, :eager_graph => { :interface => { :ip_leases => :ip_address }} do |ds|
    #  ds.alives
    #end

    subset(:alives, {})

    one_to_many :routes, :class=>Route do |ds|
      Route.dataset.join_table(
        :inner, :interfaces,
        {interfaces__id: :routes__interface_id}
      ).join_table(
        :left, :ip_leases,
        {ip_leases__interface_id: :interfaces__id}
      ).join_table(
        :inner, :ip_addresses,
        {ip_addresses__id: :ip_leases__ip_address_id} & {ip_addresses__network_id: self.id}
      ).select_all(:routes).alives
    end
  end
end
