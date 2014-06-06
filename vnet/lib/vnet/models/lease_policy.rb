# -*- coding: utf-8 -*-

module Vnet::Models
  class LeasePolicy < Base
    taggable 'lp'

    plugin :paranoia

    many_to_many :networks, :join_table => :lease_policy_base_networks
    one_to_many :lease_policy_base_networks

    many_to_many :interfaces, :join_table => :lease_policy_base_interfaces
    one_to_many :lease_policy_base_interfaces

    one_to_many :lease_policy_ip_lease_containers
    many_to_many :ip_lease_containers, :join_table => :lease_policy_ip_lease_containers

    one_to_many :lease_policy_ip_retention_containers
    many_to_many :ip_retention_containers, :join_table => :lease_policy_ip_retention_containers

    plugin :association_dependencies,
      lease_policy_base_networks: :destroy,
      lease_policy_base_interfaces: :destroy,
      lease_policy_ip_lease_containers: :destroy,
      lease_policy_ip_retention_containers: :destroy

    def self.find_by_interface(id)
      dataset.join_table(
        :left, :lease_policy_base_interfaces,
        {lease_policy_base_interfaces__lease_policy_id: :lease_policies__id}
      ).where(lease_policy_base_interfaces__interface_id: id).select_all(:lease_policies).all
    end

    def ip_leases_count
      self.ip_retention_container.ip_retentions_dataset.count
    end

    def ip_leases(options)
      offset = options[:offset]
      limit = options[:limit]
      self.ip_retention_container.ip_retentions_dataset.eager({ ip_lease: [:mac_lease, { ip_address: :network }] }).offset(options[:offset]).limit(options[:limit]).all.map(&:ip_lease)
    end
  end
end
