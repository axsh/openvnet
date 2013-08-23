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
      TABLE_PHYSICAL_SRC = 12

      TABLE_ROUTER_ENTRY = 13
      TABLE_ROUTER_SRC = 14
      TABLE_ROUTER_LINK = 15
      TABLE_ROUTER_DST = 16

      TABLE_ARP_LOOKUP = 17

      TABLE_VIRTUAL_DST = 18
      TABLE_PHYSICAL_DST = 19

      # Route based on the mac address only.
      TABLE_MAC_ROUTE = 30

      # Only output to local interface's.
      TABLE_METADATA_LOCAL        = 31

      # Send packet to all ports if marked as a flood flow, starting from
      # the route table.
      TABLE_METADATA_ROUTE        = 32
      TABLE_METADATA_SEGMENT      = 33
      TABLE_METADATA_TUNNEL_IDS   = 34
      TABLE_METADATA_TUNNEL_PORTS = 35

      # A table for sending packets to the controller after applying
      # non-action instructions such as 'write_metadata'.
      TABLE_OUTPUT_CONTROLLER     = 36

      # Send packet to a known datapath id, e.g. using an eth port or
      # tunnel port.
      #
      # Note, this table could later be used to automatically create
      # tunnels independently of installed flows.
      TABLE_OUTPUT_DP_ROUTE_LINK  = 37
      TABLE_OUTPUT_DATAPATH       = 38

      #
      # Metadata, tunnel and cookie flags and masks:
      #

      COOKIE_PREFIX_SHIFT = 48

      COOKIE_PREFIX_COLLECTION     = 0x1
      COOKIE_PREFIX_DP_NETWORK     = 0x2
      COOKIE_PREFIX_NETWORK        = 0x3
      COOKIE_PREFIX_PACKET_HANDLER = 0x4
      COOKIE_PREFIX_PORT           = 0x5
      COOKIE_PREFIX_ROUTE          = 0x6
      COOKIE_PREFIX_ROUTE_LINK     = 0x7
      COOKIE_PREFIX_SERVICE        = 0x8
      COOKIE_PREFIX_SWITCH         = 0x9
      COOKIE_PREFIX_TUNNEL         = 0x10
      COOKIE_PREFIX_VIF            = 0x11

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
      METADATA_FLAG_ARP_LOOKUP = (0x100 << METADATA_FLAGS_SHIFT)

      METADATA_TYPE_SHIFT      = 56
      METADATA_TYPE_MASK       = (0xff << METADATA_TYPE_SHIFT)

      METADATA_TYPE_COLLECTION = (0x1 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_DATAPATH   = (0x2 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_NETWORK    = (0x3 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_PORT       = (0x4 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_ROUTE      = (0x5 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_ROUTE_LINK = (0x6 << METADATA_TYPE_SHIFT)

      METADATA_VALUE_MASK = 0xffffffff

      TUNNEL_FLAG = (0x1 << 31)
      TUNNEL_FLAG_MASK = 0x80000000
      TUNNEL_NETWORK_MASK = 0x7fffffff

      TUNNEL_ROUTE_LINK = 0x1

    end
  end
end
