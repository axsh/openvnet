# -*- coding: utf-8 -*-
module Vnet
  module Event

    #
    # interface event
    #

    # interface
    ADDED_INTERFACE = "added_interface"
    REMOVED_INTERFACE = "removed_interface"
    INITIALIZED_INTERFACE = "initialized_interface"
    UPDATED_INTERFACE = "updated_interface"
    ENABLED_INTERFACE_FILTERING = "enabled_interface_filtering"
    DISABLED_INTERFACE_FILTERING = "disabled_interface_filtering"

    # ipv4 address
    LEASED_IPV4_ADDRESS = "leased_ipv4_address"
    RELEASED_IPV4_ADDRESS = "released_ipv4_address"

    # mac address
    LEASED_MAC_ADDRESS = "leased_mac_address"
    RELEASED_MAC_ADDRESS = "released_mac_address"

    # active_datapath
    REMOVED_ACTIVE_DATAPATH = "removed_active_datapath"

    #
    # datapath event
    #
    ADDED_DATAPATH = "added_datapath"
    REMOVED_DATAPATH = "removed_datapath"
    INITIALIZED_DATAPATH = "initialized_datapath"

    #
    # network event
    #
    INITIALIZED_NETWORK = "initialized_network"

    #
    # datapath_network event
    #
    ADDED_DATAPATH_NETWORK = "added_datapath_network"
    REMOVED_DATAPATH_NETWORK = "removed_datapath_network"

    #
    # lease policy event
    #
    INITIALIZED_LEASE_POLICY = "initialized_lease_policy"
    ADDED_LEASE_POLICY = "added_lease_policy"
    REMOVED_LEASE_POLICY = "removed_lease_policy"

    #
    # route event
    #
    INITIALIZED_ROUTE = "initialized_route"
    ADDED_ROUTE = "added_route"
    REMOVED_ROUTE = "removed_route"

    #
    # router event
    #
    INITIALIZED_ROUTER = "initialized_router"
    ADDED_ROUTER = "added_router"
    REMOVED_ROUTER = "removed_router"

    #
    # service event
    #
    ADDED_SERVICE = "added_service"
    REMOVED_SERVICE = "removed_service"
    INITIALIZED_SERVICE = "initialized_service"

    #
    # translation event
    #
    INITIALIZED_TRANSLATION = "initialized_translation"

    #
    # tunnel event
    #
    ADDED_TUNNEL = "added_tunnel"
    REMOVED_TUNNEL = "removed_tunnel"
    INITIALIZED_TUNNEL = "initialized_tunnel"

    #
    # port event
    #
    INITIALIZED_PORT = "initialized_port"
    FINALIZED_PORT = "finalized_port"

    #
    # filter event
    #
    INITIALIZED_FILTER = "initialized_filter"
    UPDATED_SG_RULES = "updated_rules"
    UPDATED_SG_ISOLATION = "updated_isolation"
    ADDED_INTERFACE_TO_SG = "added_interface_to_sg"
    REMOVED_INTERFACE_FROM_SG = "removed_interface_from_sg"

    #
    # dns service
    #
    ADDED_DNS_SERVICE = "added_dns_service"
    REMOVED_DNS_SERVICE = "removed_dns_service"
    UPDATED_DNS_SERVICE = "updated_dns_service"

    #
    # dns record
    #
    ADDED_DNS_RECORD = "added_dns_record"
    REMOVED_DNS_RECORD = "removed_dns_record"
  end
end
