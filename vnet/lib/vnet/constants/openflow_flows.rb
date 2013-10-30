# -*- coding: utf-8 -*-

module Vnet
  module Constants
    module OpenflowFlows

      #
      # OpenFlow tables:
      #

      # Default table used by all incoming packets.
      TABLE_CLASSIFIER = 0

      # Handle matching of incoming packets on host ports.
      TABLE_HOST_PORTS = 2

      # Straight-forward routing of packets to the port tied to the
      # destination mac address, which includes all non-virtual
      # networks.
      TABLE_TUNNEL_PORTS = 3
      TABLE_TUNNEL_NETWORK_IDS = 4

      TABLE_LOCAL_PORT = 6

      # For packets explicitly marked as being from the controller.
      #
      # Some packets are handed to the controller after modifications,
      # and as such can't be handled again by the classifier in the
      # normal fashion. The in_port is explicitly set to
      # OFPP_CONTROLLER.
      TABLE_CONTROLLER_PORT = 7

      # Translation layer for vlan
      TABLE_EDGE_SRC = 8
      TABLE_EDGE_DST = 9
      TABLE_INTERFACE_EGRESS_FILTER = 10

      TABLE_INTERFACE_CLASSIFIER = 11

      # Initial verification of network number and application of global
      # filtering rules.
      #
      # The network number stored in bits [32,48> are used to identify
      # the network, and zero is assumped to be destined for what is
      # currently known as the 'physical' network.
      #
      # Later we will always require a network number to be supplied.
      TABLE_NETWORK_SRC_CLASSIFIER = 20

      TABLE_VIRTUAL_SRC       = 21
      TABLE_PHYSICAL_SRC      = 22

      TABLE_ROUTER_CLASSIFIER = 23
      TABLE_ROUTER_INGRESS    = 24
      TABLE_ROUTE_LINK        = 25

      TABLE_ROUTER_DST        = 27

      TABLE_ARP_LOOKUP        = 28

      TABLE_NETWORK_DST_CLASSIFIER = 30
      TABLE_VIRTUAL_DST            = 31
      TABLE_PHYSICAL_DST           = 32

      TABLE_INTERFACE_INGRESS_FILTER = 33
      TABLE_INTERFACE_VIF     = 34

      # Route based on the mac address only.
      #
      # Deprecated...
      TABLE_MAC_ROUTE       = 35

      TABLE_FLOOD_SIMULATED = 40
      TABLE_FLOOD_LOCAL     = 41
      TABLE_FLOOD_ROUTE     = 42
      TABLE_FLOOD_SEGMENT   = 43
      TABLE_FLOOD_TUNNELS   = 44

      # A table for sending packets to the controller after applying
      # non-action instructions such as 'write_metadata'.
      TABLE_OUTPUT_CONTROLLER     = 50

      # Send packet to a known datapath id, e.g. using an eth port or
      # tunnel port.
      #
      # Note, this table could later be used to automatically create
      # tunnels independently of installed flows.
      TABLE_OUTPUT_DP_ROUTE_LINK  = 51
      TABLE_OUTPUT_DATAPATH       = 52
      TABLE_OUTPUT_INTERFACE      = 53

      #
      # Cookie constants:
      #

      COOKIE_ID_MASK = (0xffffffff)

      COOKIE_TAG_SHIFT = 32
      COOKIE_TAG_MASK = (0xffffff << COOKIE_TAG_SHIFT)

      COOKIE_PREFIX_SHIFT = 56
      COOKIE_PREFIX_MASK = (0xff << COOKIE_PREFIX_SHIFT)

      COOKIE_PREFIX_DP_NETWORK     = 0x2
      COOKIE_PREFIX_NETWORK        = 0x3
      COOKIE_PREFIX_PACKET_HANDLER = 0x4
      COOKIE_PREFIX_PORT           = 0x5
      COOKIE_PREFIX_ROUTE          = 0x6
      COOKIE_PREFIX_ROUTE_LINK     = 0x7
      COOKIE_PREFIX_SERVICE        = 0x8
      COOKIE_PREFIX_SWITCH         = 0x9
      COOKIE_PREFIX_TUNNEL         = 0xa
      COOKIE_PREFIX_VIF            = 0xb
      COOKIE_PREFIX_INTERFACE      = 0xc
      COOKIE_PREFIX_TRANSLATION    = 0xd
      COOKIE_PREFIX_SECURITY_GROUP = 0xe

      COOKIE_TYPE_DP_NETWORK     = (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_NETWORK        = (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_PACKET_HANDLER = (COOKIE_PREFIX_PACKET_HANDLER << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_PORT           = (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_ROUTE          = (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_ROUTE_LINK     = (COOKIE_PREFIX_ROUTE_LINK << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_SERVICE        = (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_SWITCH         = (COOKIE_PREFIX_SWITCH << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_TUNNEL         = (COOKIE_PREFIX_TUNNEL << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_VIF            = (COOKIE_PREFIX_VIF << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_INTERFACE      = (COOKIE_PREFIX_INTERFACE << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_TRANSLATION    = (COOKIE_PREFIX_TRANSLATION << COOKIE_PREFIX_SHIFT)

      #
      # Metadata constants:
      #

      METADATA_FLAGS_SHIFT = 40
      METADATA_FLAGS_MASK = (0xffff << METADATA_FLAGS_SHIFT)

      METADATA_FLAG_VIRTUAL    = (0x001 << METADATA_FLAGS_SHIFT)
      METADATA_FLAG_PHYSICAL   = (0x002 << METADATA_FLAGS_SHIFT)
      METADATA_FLAG_LOCAL      = (0x004 << METADATA_FLAGS_SHIFT)
      METADATA_FLAG_REMOTE     = (0x008 << METADATA_FLAGS_SHIFT)
      METADATA_FLAG_FLOOD      = (0x010 << METADATA_FLAGS_SHIFT)
      METADATA_FLAG_VIF        = (0x020 << METADATA_FLAGS_SHIFT)
      METADATA_FLAG_MAC2MAC    = (0x040 << METADATA_FLAGS_SHIFT)
      METADATA_FLAG_TUNNEL     = (0x080 << METADATA_FLAGS_SHIFT)

      # Allow reflection for this packet, such that if the ingress
      # port is the same as the egress port we will use the
      # 'output:OFPP_IN_PORT' action.
      METADATA_FLAG_REFLECTION = (0x100 << METADATA_FLAGS_SHIFT)

      # Don't pass this packet to the controller, e.g. to look up
      # routing information.
      METADATA_FLAG_NO_CONTROLLER = (0x200 << METADATA_FLAGS_SHIFT)

      METADATA_TYPE_SHIFT      = 56
      METADATA_TYPE_MASK       = (0xff << METADATA_TYPE_SHIFT)

      METADATA_TYPE_DATAPATH   = (0x2 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_NETWORK    = (0x3 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_PORT       = (0x4 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_ROUTE      = (0x5 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_ROUTE_LINK = (0x6 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_INTERFACE  = (0x7 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_EDGE_TO_VIRTUAL = (0x8 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_VIRTUAL_TO_EDGE = (0x9 << METADATA_TYPE_SHIFT)

      METADATA_VALUE_MASK = 0xffffffff

      #
      # Tunnel constants:
      #

      TUNNEL_FLAG = (0x1 << 31)
      TUNNEL_FLAG_MASK = 0x80000000
      TUNNEL_NETWORK_MASK = 0x7fffffff

      TUNNEL_ROUTE_LINK = 0x1

    end
  end
end
