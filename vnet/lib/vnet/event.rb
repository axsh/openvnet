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
    LeasedIpv4Address = "leased_ipv4_address"
    ReleasedIpv4Address = "released_ipv4_address"

    # mac address
    LeasedMacAddress = "leased_mac_address"
    ReleasedMacAddress = "released_mac_address"

    #
    # datapatath event
    #
    INITIALIZED_DATAPATH = "initialized_datapath"

    #
    # network event
    #
    INITIALIZED_NETWORK = "initialized_network"

    #
    # service event
    #
    INITIALIZED_SERVICE = "initialized_service"

    #
    # tunnel event
    #
    INITIALIZED_TUNNEL = "initialized_tunnel"
  end
end
