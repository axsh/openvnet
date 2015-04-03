# -*- coding: utf-8 -*-

module Vnet::Models
  class Interface < Base
    taggable 'if'

    plugin :paranoia_is_deleted

    #
    # 0001_origin
    #
    one_to_many :active_interfaces
    one_to_many :datapath_networks
    one_to_many :datapath_route_links
    one_to_many :interface_ports
    one_to_many :ip_leases
    one_to_many :mac_leases
    one_to_many :network_services
    one_to_many :routes
    one_to_many :security_group_interfaces
    one_to_many :translations

    many_to_many :ip_addresses, :join_table => :ip_leases, :conditions => "ip_leases.deleted_at is null"

    one_to_many :src_tunnels, :class => Tunnel, :key => :src_interface_id
    one_to_many :dst_tunnels, :class => Tunnel, :key => :dst_interface_id

    one_to_many :security_group_interfaces
    many_to_many :security_groups, :join_table => :security_group_interfaces, :conditions => "security_group_interfaces.deleted_at is null"

    #
    # 0002_services
    #
    one_to_many :lease_policy_base_interfaces
    many_to_many :lease_policies, :join_table => :lease_policy_base_interfaces, :conditions => "lease_policy_base_interfaces.deleted_at is null"

    plugin :association_dependencies,
    # 0001_origin
    active_interfaces: :destroy,
    datapath_networks: :destroy,
    datapath_route_links: :destroy,
    interface_ports: :destroy,
    ip_leases: :destroy,
    mac_leases: :destroy,
    network_services: :destroy,
    routes: :destroy,
    security_group_interfaces: :destroy,
    src_tunnels: :destroy,
    dst_tunnels: :destroy,
    translations: :destroy,
    # 0002_services
    lease_policy_base_interfaces: :destroy

  end
end
