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

    many_to_one :ip_retention_container

    plugin :association_dependencies,
      lease_policy_base_networks: :destroy,
      lease_policy_base_interfaces: :destroy,
      lease_policy_ip_lease_containers: :destroy,
      ip_retention_container: :destroy

    def self.find_by_interface(id)
      dataset.join_table(
        :left, :lease_policy_base_interfaces,
        {lease_policy_base_interfaces__lease_policy_id: :lease_policies__id}
      ).where(lease_policy_base_interfaces__interface_id: id).select_all(:lease_policies).all
    end

    def lease_time
      ip_retention_container ? ip_retention_container.lease_time : nil
    end

    def grace_time
      ip_retention_container ? ip_retention_container.grace_time : nil
    end

    def to_hash
      super.merge({
        lease_time: lease_time,
        grace_time: grace_time
      })
    end
  end
end
