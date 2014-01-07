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

    # ipv4 address
    LEASED_IPV4_ADDRESS = "leased_ipv4_address"
    RELEASED_IPV4_ADDRESS = "released_ipv4_address"

    # mac address
    LEASED_MAC_ADDRESS = "leased_mac_address"
    RELEASED_MAC_ADDRESS = "released_mac_address"

    #
    # datapatath event
    #
    INITIALIZED_DATAPATH = "initialized_datapath"

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
    INITIALIZED_SERVICE = "initialized_service"
    ADDED_SERVICE = "added_service"
    REMOVED_SERVICE = "removed_service"

    #
    # translation event
    #
    INITIALIZED_TRANSLATION = "initialized_translation"

    #
    # tunnel event
    #
    INITIALIZED_TUNNEL = "initialized_tunnel"

    #
    # port event
    #
    INITIALIZED_PORT = "initialized_port"
    FINALIZED_PORT = "finalized_port"
  end
end
