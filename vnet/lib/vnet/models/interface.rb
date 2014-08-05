# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class Interface < Base
    taggable 'if'

    plugin :paranoia_is_deleted

    one_to_many :active_interfaces
    one_to_many :interface_ports
    one_to_many :ip_leases
    one_to_many :mac_leases
    one_to_many :network_services
    one_to_many :routes
    one_to_many :translations

    many_to_many :ip_addresses, :join_table => :ip_leases, :conditions => "ip_leases.deleted_at is null"

    # TODO: Rename to security_group_interfaces, and move associations
    # and helper methods to security group models. Same goes for lease policies.
    one_to_many :security_group_interfaces
    many_to_many :security_groups, :join_table => :security_group_interfaces, :conditions => "security_group_interfaces.deleted_at is null"

    many_to_many :lease_policies, :join_table => :lease_policy_base_interfaces, :conditions => "lease_policy_base_interfaces.deleted_at is null"
    one_to_many :lease_policy_base_interfaces

    plugin :association_dependencies,
      :active_interfaces => :destroy,
      :interface_ports => :destroy,
      :ip_leases => :destroy,
      :mac_leases => :destroy,
      :network_services => :destroy,
      :routes => :destroy,
      :translations => :destroy

  end
end
