# -*- coding: utf-8 -*-

module Vnet::Models
  class Network < Base
    taggable 'nw'
    plugin :paranoia_is_deleted

    many_to_one :segment

    one_to_many :ip_addresses
    one_to_many :routes
    one_to_many :tunnels

    one_to_many :active_networks
    one_to_many :interface_networks
    one_to_many :topology_networks

    many_to_many :datapaths, :join_table => :datapath_networks, :conditions => "datapath_networks.deleted_at is null"
    one_to_many :datapath_networks

    one_to_many :lease_policy_base_networks
    many_to_many :lease_policies, :join_table => :lease_policy_base_networks, :conditions => "lease_policy_base_networks.deleted_at is null"

    plugin :association_dependencies,
    # 0001_origin
    ip_addresses: :destroy,
    datapath_networks: :destroy,
    routes: :destroy,
    # 0002_services
    lease_policy_base_networks: :destroy,
    # 0004_active_items
    active_networks: :destroy,
    # 0009_topology
    topology_networks: :destroy,
    # 0011_assoc_interface
    interface_networks: :destroy

    def before_create
      self.domain_name = self[:uuid] if self.domain_name.nil?

      super
    end

  end
end
