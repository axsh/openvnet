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
    # Datapath events:
    #
    ADDED_DATAPATH = 'added_datapath'
    REMOVED_DATAPATH = 'removed_datapath'
    INITIALIZED_DATAPATH = 'initialized_datapath'

    ACTIVATE_NETWORK_ON_HOST = 'activate_network_on_host'
    DEACTIVATE_NETWORK_ON_HOST = 'deactivate_network_on_host'

    ADDED_DATAPATH_NETWORK = 'added_datapath_network'
    REMOVED_DATAPATH_NETWORK = 'removed_datapath_network'
    ACTIVATE_DATAPATH_NETWORK = 'activate_datapath_network'
    DEACTIVATE_DATAPATH_NETWORK = 'deactivate_datapath_network'

    ACTIVATE_ROUTE_LINK_ON_HOST = 'activate_route_link_on_host'
    DEACTIVATE_ROUTE_LINK_ON_HOST = 'deactivate_route_link_on_host'

    ADDED_DATAPATH_ROUTE_LINK = 'added_datapath_route_link'
    REMOVED_DATAPATH_ROUTE_LINK = 'removed_datapath_route_link'
    ACTIVATE_DATAPATH_ROUTE_LINK = 'activate_datapath_route_link'
    DEACTIVATE_DATAPATH_ROUTE_LINK = 'deactivate_datapath_route_link'

    #
    # network event
    #
    INITIALIZED_NETWORK = "initialized_network"

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

    TUNNEL_UPDATE_NETWORKS = "tunnel_update_networks"

    ADDED_HOST_DATAPATH_NETWORK = "added_host_datapath_network"
    ADDED_REMOTE_DATAPATH_NETWORK = "added_remote_datapath_network"
    ADDED_HOST_DATAPATH_ROUTE_LINK = "added_host_datapath_route_link"
    ADDED_REMOTE_DATAPATH_ROUTE_LINK = "added_remote_datapath_route_link"
    REMOVED_HOST_DATAPATH_NETWORK = "removed_host_datapath_network"
    REMOVED_REMOTE_DATAPATH_NETWORK = "removed_remote_datapath_network"
    REMOVED_HOST_DATAPATH_ROUTE_LINK = "removed_host_datapath_route_link"
    REMOVED_REMOTE_DATAPATH_ROUTE_LINK = "removed_remote_datapath_route_link"

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
    UPDATED_SG_IP_ADDRESSES = "updated_sg_ip_addresses"
    ADDED_INTERFACE_TO_SG = "added_interface_to_sg"
    REMOVED_INTERFACE_FROM_SG = "removed_interface_from_sg"
    REMOVED_SECURITY_GROUP = "removed_security_group"

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
