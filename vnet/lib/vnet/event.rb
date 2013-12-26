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
  end
end
