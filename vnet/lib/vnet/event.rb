# -*- coding: utf-8 -*-
module Vnet
  module Event

    # *_INITIALIZED
    #
    # First event queued after the non-yielding and non-blocking
    # initialization of an item query from the database.
    #
    # *_UNLOAD_ITEM
    #
    # When the node wants to unload it's own loaded items the
    # 'unload_item' event should be used instead of 'deleted_item'.
    #
    # *_CREATED_ITEM
    #
    # The item was added to the database and basic information of
    # the item sent to relevant nodes. The manager should decide if it
    # should initialize the item or not.
    #
    # *_DELETED_ITEM
    #
    # The item was deleted from the database and should be unloaded
    # from all nodes.

    #
    # Datapath events:
    #
    DATAPATH_INITIALIZED = 'datapath_initialized'
    DATAPATH_UNLOAD_ITEM = 'datapath_unload_item'
    DATAPATH_CREATED_ITEM = 'datapath_created_item'
    DATAPATH_DELETED_ITEM = 'datapath_deleted_item'

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
    # Interface events:
    #

    INTERFACE_INITIALIZED = "interface_initialized"
    INTERFACE_UNLOAD_ITEM = "interface_unload_item"
    INTERFACE_CREATED_ITEM = "interface_created_item"
    INTERFACE_DELETED_ITEM = "interface_deleted_item"

    INTERFACE_ACTIVATE_PORT = "interface_activate_port"
    INTERFACE_DEACTIVATE_PORT = "interface_deactivate_port"

    INTERFACE_UPDATED = "interface_updated"
    INTERFACE_ENABLED_FILTERING = "interface_enabled_filtering"
    INTERFACE_DISABLED_FILTERING = "interface_disabled_filtering"
    INTERFACE_REMOVE_ALL_ACTIVE_DATAPATHS = "interface_remove_all_active_datapaths"

    # MAC and IPv4 addresses:
    INTERFACE_LEASED_MAC_ADDRESS = "interface_leased_mac_address"
    INTERFACE_RELEASED_MAC_ADDRESS = "interface_released_mac_address"
    INTERFACE_LEASED_IPV4_ADDRESS = "interface_leased_ipv4_address"
    INTERFACE_RELEASED_IPV4_ADDRESS = "interface_released_ipv4_address"

    #
    # Network event:
    #

    NETWORK_INITIALIZED = "network_initialized"
    NETWORK_UNLOAD_ITEM = "network_unload_item"
    NETWORK_DELETED_ITEM = "network_deleted_item"

    NETWORK_UPDATE_ITEM_STATES = "network_update_item_states"

    #
    # lease policy event
    #
    INITIALIZED_LEASE_POLICY = "initialized_lease_policy"
    ADDED_LEASE_POLICY = "added_lease_policy"
    REMOVED_LEASE_POLICY = "removed_lease_policy"

    #
    # Port events:
    #

    PORT_INITIALIZED = "port_initialized"
    PORT_FINALIZED = "port_finalized"

    PORT_ATTACH_INTERFACE = "port_attach_interface"
    PORT_DETACH_INTERFACE = "port_detach_interface"

    #
    # Route events:
    #
    ROUTE_INITIALIZED = "route_initialized"
    ROUTE_UNLOAD_ITEM = "route_unload_item"
    ROUTE_CREATED_ITEM = "route_created_item"
    ROUTE_DELETED_ITEM = "route_deleted_item"

    ROUTE_ACTIVATE_NETWORK = "route_activate_network"
    ROUTE_DEACTIVATE_NETWORK = "route_deactivate_network"

    ROUTE_ACTIVATE_ROUTE_LINK = "route_activate_route_link"
    ROUTE_DEACTIVATE_ROUTE_LINK = "route_deactivate_route_link"

    #
    # router event
    #
    ROUTER_INITIALIZED = "router_initialized"
    ROUTER_UNLOAD_ITEM = "router_unload_item"
    ROUTER_CREATED_ITEM = "router_created_item"
    ROUTER_DELETED_ITEM = "router_deleted_item"

    #
    # Service events:
    #
    SERVICE_INITIALIZED = "service_initialized"
    SERVICE_UNLOAD_ITEM = "service_unload_item"
    SERVICE_CREATED_ITEM = "service_created_item"
    SERVICE_DELETED_ITEM = "service_deleted_item"

    SERVICE_ACTIVATE_INTERFACE = "service_activate_interface"
    SERVICE_DEACTIVATE_INTERFACE = "service_deactivate_interface"

    #
    # Translation events:
    #
    TRANSLATION_INITIALIZED = "translation_initialized"
    TRANSLATION_UNLOAD_ITEM = "translation_unload_item"
    TRANSLATION_CREATED_ITEM = "translation_created_item"
    TRANSLATION_DELETED_ITEM = "translation_deleted_item"

    TRANSLATION_ACTIVATE_INTERFACE = "translation_activate_interface"
    TRANSLATION_DEACTIVATE_INTERFACE = "translation_deactivate_interface"
    TRANSLATION_ADDED_STATIC_ADDRESS = "translation_added_static_address"
    TRANSLATION_REMOVED_STATIC_ADDRESS = "translation_removed_static_address"

    #
    # tunnel event
    #
    ADDED_TUNNEL = "added_tunnel"
    REMOVED_TUNNEL = "removed_tunnel"
    INITIALIZED_TUNNEL = "initialized_tunnel"

    TUNNEL_UPDATE_PROPERTY_STATES = "tunnel_update_property_states"

    ADDED_HOST_DATAPATH_NETWORK = "added_host_datapath_network"
    ADDED_REMOTE_DATAPATH_NETWORK = "added_remote_datapath_network"
    ADDED_HOST_DATAPATH_ROUTE_LINK = "added_host_datapath_route_link"
    ADDED_REMOTE_DATAPATH_ROUTE_LINK = "added_remote_datapath_route_link"
    REMOVED_HOST_DATAPATH_NETWORK = "removed_host_datapath_network"
    REMOVED_REMOTE_DATAPATH_NETWORK = "removed_remote_datapath_network"
    REMOVED_HOST_DATAPATH_ROUTE_LINK = "removed_host_datapath_route_link"
    REMOVED_REMOTE_DATAPATH_ROUTE_LINK = "removed_remote_datapath_route_link"

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
    SERVICE_ADDED_DNS = "added_dns_service"
    SERVICE_REMOVED_DNS = "removed_dns_service"
    SERVICE_UPDATED_DNS = "updated_dns_service"

    #
    # dns record
    #
    ADDED_DNS_RECORD = "added_dns_record"
    REMOVED_DNS_RECORD = "removed_dns_record"

    #
    # Ip retention container events:
    #
    IP_RETENTION_CONTAINER_INITIALIZED = 'ip_retention_container_initialized'
    IP_RETENTION_CONTAINER_UNLOAD_ITEM = 'ip_retention_container_unload_item'
    IP_RETENTION_CONTAINER_CREATED_ITEM = 'ip_retention_container_created_item'
    IP_RETENTION_CONTAINER_DELETED_ITEM = 'ip_retention_container_deleted_item'
    IP_RETENTION_CONTAINER_ADDED_IP_RETENTION = 'ip_retention_container_added_ip_retention'
    IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION = 'ip_retention_container_removed_ip_retention'
    IP_RETENTION_CONTAINER_EXPIRED_IP_RETENTION = 'ip_retention_container_expired_ip_retention'
  end
end
