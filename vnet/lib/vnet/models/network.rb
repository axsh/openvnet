# -*- coding: utf-8 -*-

module Vnet::Models
  class Network < Base
    taggable 'nw'
    plugin :paranoia_is_deleted

    #
    # 0001_origin
    #
    one_to_many :ip_addresses
    one_to_many :datapath_networks
    one_to_many :routes
    one_to_many :tunnels
    one_to_many :vlan_translations

    many_to_many :datapaths, :join_table => :datapath_networks, :conditions => "datapath_networks.deleted_at is null"

    #
    # 0002_services
    #
    one_to_many :lease_policy_base_networks
    many_to_many :lease_policies, :join_table => :lease_policy_base_networks, :conditions => "lease_policy_base_networks.deleted_at is null"

    #
    # 0004_active_items
    #
    one_to_many :active_networks

    #
    # 0009_translation_static_address_with_network_uuid
    #
    one_to_many :tsa_ingress, :class => TranslationStaticAddress, :key => :ingress_network_id
    one_to_many :tsa_egress, :class => TranslationStaticAddress, :key => :egress_network_id

    plugin :association_dependencies,
    # 0001_origin
    ip_addresses: :destroy,
    datapath_networks: :destroy,
    routes: :destroy,
    vlan_translations: :destroy,
    # 0002_services
    lease_policy_base_networks: :destroy,
    # 0004_active_items
    active_networks: :destroy,
    # 0009_translation_static_address_with_network_uuid
    tsa_ingress: :destroy,
    tsa_egress: :destroy

  end
end
