# -*- coding: utf-8 -*-

module Vnet::Models
  class Network < Base
    taggable 'nw'

    plugin :paranoia_with_unique_constraint

    one_to_many :datapath_networks
    many_to_many :datapaths, :join_table => :datapath_networks
    one_to_many :ip_addresses
    one_to_many :tunnels
    one_to_many :ip_leases

    many_to_many :lease_policies, :join_table => :lease_policy_base_networks
    one_to_many :lease_policy_base_networks

    many_to_many :network_services do |ds|
      NetworkService.join_table(
        :inner, :interfaces,
        {interfaces__id: :network_services__interface_id}
      ).join_table(
        :left, :ip_leases,
        {ip_leases__interface_id: :interfaces__id}
      ).join_table(
        :inner, :ip_addresses,
        {ip_addresses__id: :ip_leases__ip_address_id} & {ip_addresses__network_id: self.id}
      ).select_all(:network_services).alives
    end

    one_to_many :routes, :class=>Route do |ds|
      Route.join_table(
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

    def self.find_by_mac_address(mac_address)
      dataset.join_table(
        :left, :ip_addresses,
        {ip_addresses__network_id: :networks__id}
      ).join_table(
        :inner, :ip_leases,
        {ip_leases__ip_address_id: :ip_addresses__id}
      ).join_table(
        :inner, :mac_leases,
        {ip_leases__mac_lease_id: :mac_leases__id}
      ).join_table(
        :inner, :mac_addresses,
        {mac_addresses__id: :mac_leases__mac_address_id}
      ).where(mac_addresses__mac_address: mac_address).select_all(:networks).alives.first
    end

    subset(:alives, {})

    def before_destroy
      [DatapathNetwork, IpAddress, Route, VlanTranslation].each do |klass|
        if klass[network_id: id]
          raise DeleteRestrictionError, "cannot delete network(id: #{id}) if any dependency still exists. dependency: #{klass}"
        end
      end
    end
  end
end
