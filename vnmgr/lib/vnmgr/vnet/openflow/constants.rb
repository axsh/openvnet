# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  MW = Vnmgr::ModelWrappers

  module Constants
    # Default table used by all incoming packets.
    TABLE_CLASSIFIER = 0

    # Handle matching of incoming packets on host ports.
    TABLE_HOST_PORTS = 2

    # Straight-forward routing of packets to the port tied to the
    # destination mac address, which includes all non-virtual
    # networks.
    TABLE_TUNNEL_PORTS = 3

    # Initial verification of network number and application of global
    # filtering rules.
    #
    # The network number stored in bits [32,48> are used to identify
    # the network, and zero is assumped to be destined for what is
    # currently known as the 'physical' network.
    #
    # Later we will always require a network number to be supplied.
    TABLE_NETWORK_CLASSIFIER = 10

    TABLE_VIRTUAL_SRC = 11

    TABLE_ROUTER_ENTRY = 14
    TABLE_ROUTER_SRC = 15
    TABLE_ROUTER_DST = 16
    TABLE_ROUTER_EXIT = 17

    TABLE_VIRTUAL_DST = 18

    # Route based on the mac address only.
    TABLE_MAC_ROUTE = 30

    # Output to port based on the metadata field. OpenFlow 1.3 does
    # not seem to have any action allowing us to output to a port
    # using the metadata field directly, so a separate table is
    # required.
    TABLE_METADATA_LOCAL = 31
    TABLE_METADATA_ROUTE = 32
    TABLE_METADATA_SEGMENT = 33
    TABLE_METADATA_TUNNEL = 34

    #
    # Legacy tables yet to be integrated in the new table ordering:
    #

    # Routing to non-virtual networks with filtering applied.
    #
    # Due to limitations in the rules we can use the filter rules
    # for the destination must be applied first, and its port number
    # loaded into a registry.
    #
    # The source will then apply filtering rules and output to the
    # port number found in registry 1.
    TABLE_PHYSICAL_DST = 20
    TABLE_PHYSICAL_SRC = 21

    # The ARP antispoof table ensures no ARP packet SHA or SPA field
    # matches the mac address owned by another port.
    #
    # If valid, the next table routes the packet to the right port.
    TABLE_ARP_ANTISPOOF = 22
    TABLE_ARP_ROUTE = 23

    #
    # Metadata, tunnel and cookie flags and masks:
    #

    COOKIE_PREFIX_SHIFT = 48

    COOKIE_PREFIX_SWITCH = 0x1
    COOKIE_PREFIX_PACKET_HANDLER = 0x2
    COOKIE_PREFIX_PORT = 0x3
    COOKIE_PREFIX_NETWORK = 0x4
    COOKIE_PREFIX_DC_SEGMENT = 0x5
    COOKIE_PREFIX_TUNNEL = 0x6
    COOKIE_PREFIX_ROUTE = 0x7

    METADATA_FLAGS_MASK = (0xffff << 48)
    METADATA_FLAGS_SHIFT = 48

    METADATA_FLAG_VIRTUAL  = (0x1 << 48)
    METADATA_FLAG_PHYSICAL = (0x2 << 48)
    METADATA_FLAG_LOCAL    = (0x4 << 48)
    METADATA_FLAG_REMOTE   = (0x8 << 48)

    METADATA_PORT_MASK = 0xffffffff
    METADATA_NETWORK_MASK = (0xffff << 32)
    METADATA_NETWORK_SHIFT = 32
    
    TUNNEL_FLAG = (0x1 << 31)
    TUNNEL_FLAG_MASK = 0x80000000
    TUNNEL_NETWORK_MASK = 0x7fffffff

    #
    # Trema related constants:
    #

    MAC_BROADCAST = Trema::Mac.new('ff:ff:ff:ff:ff:ff')
  end

end
