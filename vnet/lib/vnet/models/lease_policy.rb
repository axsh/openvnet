# -*- coding: utf-8 -*-

module Vnet::Models
  class LeasePolicy < Base
    taggable 'lp'

    many_to_many :networks, :join_table => :lease_policy_base_networks
    one_to_many :lease_policy_base_networks

    many_to_many :interfaces, :join_table => :lease_policy_base_interfaces
    one_to_many :lease_policy_base_interfaces

    plugin :paranoia

    def self.find_by_interface(id)
      dataset.join_table(
        :left, :lease_policy_base_interfaces,
        {lease_policy_base_interfaces__lease_policy_id: :lease_policies__id}
      ).where(lease_policy_base_interfaces__interface_id: id).select_all(:lease_policies).all
    end

    def validate
      super
      errors.add(:lease_time, 'cannot be less than 0') if grace_time && grace_time < 0
      errors.add(:grace_time, 'cannot be less than 0') if grace_time && grace_time < 0
    end
  end
end
