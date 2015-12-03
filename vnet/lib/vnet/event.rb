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
    # Active Interface events:
    #

    ACTIVE_INTERFACE_INITIALIZED = "active_interface_initialized"
    ACTIVE_INTERFACE_UNLOAD_ITEM = "active_interface_unload_item"
    ACTIVE_INTERFACE_CREATED_ITEM = "active_interface_created_item"
    ACTIVE_INTERFACE_DELETED_ITEM = "active_interface_deleted_item"

    ACTIVE_INTERFACE_UPDATED = "active_interface_updated"

    #
    # Active Network events:
    #

    ACTIVE_NETWORK_INITIALIZED = "active_network_initialized"
    ACTIVE_NETWORK_UNLOAD_ITEM = "active_network_unload_item"
    ACTIVE_NETWORK_CREATED_ITEM = "active_network_created_item"
    ACTIVE_NETWORK_DELETED_ITEM = "active_network_deleted_item"

    #
    # Active Route Link events:
    #

    ACTIVE_ROUTE_LINK_INITIALIZED = "active_route_link_initialized"
    ACTIVE_ROUTE_LINK_UNLOAD_ITEM = "active_route_link_unload_item"
    ACTIVE_ROUTE_LINK_CREATED_ITEM = "active_route_link_created_item"
    ACTIVE_ROUTE_LINK_DELETED_ITEM = "active_route_link_deleted_item"

    #
    # Active Port events:
    #

    ACTIVE_PORT_INITIALIZED = "active_port_initialized"
    ACTIVE_PORT_UNLOAD_ITEM = "active_port_unload_item"
    ACTIVE_PORT_CREATED_ITEM = "active_port_created_item"
    ACTIVE_PORT_DELETED_ITEM = "active_port_deleted_item"

    ACTIVE_PORT_ACTIVATE = "active_port_activate"
    ACTIVE_PORT_DEACTIVATE = "active_port_deactivate"

    #
    # Datapath events:
    #
    DATAPATH_INITIALIZED = 'datapath_initialized'
    DATAPATH_UNLOAD_ITEM = 'datapath_unload_item'
    DATAPATH_CREATED_ITEM = 'datapath_created_item'
    DATAPATH_DELETED_ITEM = 'datapath_deleted_item'

    HOST_DATAPATH_INITIALIZED = 'host_datapath_initialized'
    HOST_DATAPATH_UNLOAD_ITEM = 'host_datapath_unload_item'

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

    INTERFACE_UPDATED = "interface_updated"
    INTERFACE_ENABLED_FILTERING = "interface_enabled_filtering"
    INTERFACE_DISABLED_FILTERING = "interface_disabled_filtering"

    # MAC and IPv4 addresses:
    INTERFACE_LEASED_MAC_ADDRESS = "interface_leased_mac_address"
    INTERFACE_RELEASED_MAC_ADDRESS = "interface_released_mac_address"
    INTERFACE_LEASED_IPV4_ADDRESS = "interface_leased_ipv4_address"
    INTERFACE_RELEASED_IPV4_ADDRESS = "interface_released_ipv4_address"

    #
    # Interface Port events:
    #

    INTERFACE_PORT_INITIALIZED = "interface_port_initialized"
    INTERFACE_PORT_UNLOAD_ITEM = "interface_port_unload_item"
    INTERFACE_PORT_CREATED_ITEM = "interface_port_created_item"
    INTERFACE_PORT_DELETED_ITEM = "interface_port_deleted_item"

    INTERFACE_PORT_UPDATED = "interface_port_updated"

    INTERFACE_PORT_ACTIVATE = "interface_port_activate"
    INTERFACE_PORT_DEACTIVATE = "interface_port_deactivate"

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
    LEASE_POLICY_INITIALIZED = "lease_policy_initialized"
    LEASE_POLICY_CREATED_ITEM = "lease_policy_created_item"
    LEASE_POLICY_DELETED_ITEM = "lease_policy_deleted_item"

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
    # Ip Retention Container Events:
    #
    IP_RETENTION_CONTAINER_INITIALIZED = 'ip_retention_container_initialized'
    IP_RETENTION_CONTAINER_UNLOAD_ITEM = 'ip_retention_container_unload_item'
    IP_RETENTION_CONTAINER_CREATED_ITEM = 'ip_retention_container_created_item'
    IP_RETENTION_CONTAINER_DELETED_ITEM = 'ip_retention_container_deleted_item'
    IP_RETENTION_CONTAINER_ADDED_IP_RETENTION = 'ip_retention_container_added_ip_retention'
    IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION = 'ip_retention_container_removed_ip_retention'
    IP_RETENTION_CONTAINER_LEASE_TIME_EXPIRED = 'ip_retention_container_lease_time_expired'
    IP_RETENTION_CONTAINER_GRACE_TIME_EXPIRED = 'ip_retention_container_grace_time_expired'

  end
end
