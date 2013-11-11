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

      TABLE_INTERFACE_CLASSIFIER    = 10
      TABLE_INTERFACE_EGRESS_ROUTES = 11
      TABLE_INTERFACE_EGRESS_MAC    = 12

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

      TABLE_ROUTE_INGRESS      = 33
      TABLE_ROUTE_LINK_INGRESS = 34
      TABLE_ROUTE_LINK_EGRESS  = 35
      TABLE_ROUTE_EGRESS       = 36
      TABLE_ARP_TABLE          = 37
      TABLE_ARP_LOOKUP         = 38

      TABLE_NETWORK_DST_CLASSIFIER = 40
      TABLE_VIRTUAL_DST            = 41
      TABLE_PHYSICAL_DST           = 42

      TABLE_INTERFACE_VIF     = 44

      # Route based on the mac address only.
      #
      # Deprecated...
      TABLE_MAC_ROUTE       = 45

      TABLE_FLOOD_SIMULATED = 50
      TABLE_FLOOD_LOCAL     = 51
      TABLE_FLOOD_ROUTE     = 52
      TABLE_FLOOD_SEGMENT   = 53
      TABLE_FLOOD_TUNNELS   = 54

      # A table for sending packets to the controller after applying
      # non-action instructions such as 'write_metadata'.
      TABLE_OUTPUT_CONTROLLER  = 60

      # Send packet to a known datapath id, e.g. using an eth port or
      # tunnel port.
      #
      # Note, this table could later be used to automatically create
      # tunnels independently of installed flows.

      # TODO: Fix this...
      TABLE_OUTPUT_ROUTE_LINK      = 61
      TABLE_OUTPUT_ROUTE_LINK_HACK = 62

      TABLE_OUTPUT_DATAPATH  = 63
      TABLE_OUTPUT_MAC2MAC   = 64
      TABLE_OUTPUT_INTERFACE = 65

      #
      # Cookie constants:
      #

      COOKIE_ID_MASK = (0xffffffff)

      COOKIE_TAG_SHIFT = 32
      COOKIE_TAG_MASK = (0xffffff << COOKIE_TAG_SHIFT)

      COOKIE_PREFIX_SHIFT = 56
      COOKIE_PREFIX_MASK = (0xff << COOKIE_PREFIX_SHIFT)

      COOKIE_PREFIX_DATAPATH       = 0x1
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

      COOKIE_TYPE_DATAPATH       = (COOKIE_PREFIX_DATAPATH << COOKIE_PREFIX_SHIFT)
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

      # constants for gre
      # TUNNEL_FLAG = (0x1 << 31)
      # TUNNEL_FLAG_MASK = 0x80000000
      # TUNNEL_NETWORK_MASK = 0x7fffffff

      # constants for vxlan
      TUNNEL_FLAG = (0x1 << 23)
      TUNNEL_FLAG_MASK = 0x800000
      TUNNEL_NETWORK_MASK = 0x7fffff

      TUNNEL_ROUTE_LINK = 0x1

      #
      # 802.1Q constants:
      #

      VLAN_TCI_VID_SHIFT = 12
      VLAN_TCI_DEI = (0x1 << VLAN_TCI_VID_SHIFT)
      VLAN_TCI_MASK_NO_PRIORITY = (0x0fff | VLAN_TCI_DEI)

    end
  end
end
