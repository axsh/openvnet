# -*- coding: utf-8 -*-

module Vnet
  module Constants
    module OpenflowFlows

      #
      # OpenFlow tables:
      #

      # Default table used by all incoming packets.
      TABLE_CLASSIFIER = 0

      # For packets explicitly marked as being from the controller.
      #
      # Some packets are handed to the controller after modifications,
      # and as such can't be handled again by the classifier in the
      # normal fashion. The in_port is explicitly set to
      # OFPP_CONTROLLER.
      TABLE_CONTROLLER_PORT = 1
      TABLE_LOCAL_PORT      = 2

      # Straight-forward routing of packets to the port tied to the
      # destination mac address, which includes all non-virtual
      # networks.
      TABLE_TUNNEL_IF_NIL = 3

      # Handle ingress packets to host interfaces from unmanaged
      # sources.
      TABLE_INTERFACE_INGRESS_CLASSIFIER_IF_NIL = 10
      TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL     = 11
      TABLE_INTERFACE_INGRESS_IF_SEG            = 12
      TABLE_INTERFACE_INGRESS_SEG_DPSEG         = 13
      TABLE_INTERFACE_INGRESS_IF_NW             = 14
      TABLE_INTERFACE_INGRESS_NW_DPNW           = 15
      TABLE_INTERFACE_INGRESS_RL_DPRL           = 16

      # Handle egress packets from managed interfaces.
      TABLE_INTERFACE_EGRESS_CLASSIFIER_IF_NIL  = 17
      TABLE_INTERFACE_EGRESS_STATEFUL_IF_NIL    = 18
      TABLE_INTERFACE_EGRESS_FILTER_IF_NIL      = 19
      TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL    = 20
      TABLE_INTERFACE_EGRESS_ROUTES_IF_NIL      = 21
      TABLE_INTERFACE_EGRESS_ROUTES_IF_NW       = 22

      # Initial verification of network/segment id and application of
      # global filtering rules. 
      #
      # The network/segment id stored in bits [32,48> are used to
      # identify the network/segment, and zero is assumped to be
      # destined for what is currently known as the 'physical'
      # network/segment.
      #
      # The mac learning table should only be used by remote packets,
      # although some special cases may exist thus checking for the
      # remote metdata flag is the responsibility of the flow that
      # sends the packet to these tables.
      TABLE_SEGMENT_SRC_CLASSIFIER_SEG_NIL = 25
      TABLE_NETWORK_SRC_CLASSIFIER_NW_NIL  = 26

      # In the transition from TABLE_ROUTER_EGRESS_LOOKUP_RL_NIL to
      # TABLE_ROUTE_EGRESS_LOOKUP_IF_RL the packet loses it's metadata
      # flags.
      TABLE_ROUTE_INGRESS_INTERFACE_NW_NIL   = 30
      TABLE_ROUTE_INGRESS_TRANSLATION_IF_NIL = 31
      TABLE_ROUTER_INGRESS_LOOKUP_IF_NIL     = 32
      TABLE_ROUTER_CLASSIFIER_RL_NIL         = 33
      TABLE_ROUTER_EGRESS_LOOKUP_RL_NIL      = 34
      TABLE_ROUTE_EGRESS_LOOKUP_IF_RL        = 35
      TABLE_ROUTE_EGRESS_TRANSLATION_IF_NIL  = 36
      TABLE_ROUTE_EGRESS_INTERFACE_IF_NIL    = 37

      TABLE_ARP_TABLE_NW_NIL                 = 40
      TABLE_ARP_LOOKUP_NW_NIL                = 41

      TABLE_NETWORK_DST_CLASSIFIER_NW_NIL    = 42
      TABLE_NETWORK_DST_MAC_LOOKUP_NIL_NW    = 43
      TABLE_SEGMENT_DST_CLASSIFIER_SEG_NW    = 44
      TABLE_SEGMENT_DST_MAC_LOOKUP_SEG_NW    = 45

      TABLE_INTERFACE_INGRESS_FILTER_IF_NIL        = 46
      TABLE_INTERFACE_INGRESS_FILTER_LOOKUP_IF_NIL = 47

      TABLE_FLOOD_SIMULATED_SEG_NW           = 50
      TABLE_FLOOD_LOCAL_SEG_NW               = 51
      TABLE_FLOOD_TUNNELS_SEG_NW             = 52
      TABLE_FLOOD_SEGMENT_SEG_NW             = 53

      TABLE_LOOKUP_IF_NW                     = 70
      TABLE_LOOKUP_IF_RL                     = 71
      TABLE_LOOKUP_DP_NW                     = 72
      TABLE_LOOKUP_DP_SEG                    = 73
      TABLE_LOOKUP_DP_RL                     = 74
      TABLE_LOOKUP_NW_NIL                    = 75
      TABLE_LOOKUP_SEG_NIL                   = 76

      # The 'output dp * lookup' tables use the DatapathNetwork and
      # DatapathRouteLink database entry keys to determine what source
      # interface and destination interfaces should be used for
      # packets.
      #
      # For MAC2MAC this only requires changing the destionation MAC
      # address to the one associated with that particular datapath
      # network or route link, while for tunnels the output port needs
      # to be selected from pre-created tunnels.

      TABLE_OUTPUT_HOSTIF_DST_DPN_NIL        = 80
      TABLE_OUTPUT_HOSTIF_DST_DPS_NIL        = 81
      TABLE_OUTPUT_HOSTIF_DST_DPR_NIL        = 82
      TABLE_OUTPUT_HOSTIF_SRC_NW_DIF         = 83
      TABLE_OUTPUT_HOSTIF_SRC_SEG_DIF        = 84
      TABLE_OUTPUT_HOSTIF_SRC_RL_DIF         = 85

      TABLE_OUTPUT_MAC2MAC_SIF_DIF           = 86
      TABLE_OUTPUT_TUNNEL_SIF_DIF            = 87
      TABLE_OUTPUT_CONTROLLER_SEG_NW         = 88

      # Directly output to a port type with no additional
      # actions. Usable by any table and as such need to be the last
      # tables.
      TABLE_OUT_PORT_INGRESS_IF_NIL = 90
      TABLE_OUT_PORT_EGRESS_IF_NIL  = 91
      TABLE_OUT_PORT_EGRESS_TUN_NIL = 92


      #
      # Cookie constants:
      #

      COOKIE_MASK = 0xffffffffffffffff

      COOKIE_ID_MASK = (0x7fffffff)
      COOKIE_DYNAMIC_LOAD_MASK = (0x1 << 31)

      COOKIE_TAG_SHIFT = 32
      COOKIE_TAG_MASK = (0xffffff << COOKIE_TAG_SHIFT)

      COOKIE_PREFIX_SHIFT = 56
      COOKIE_PREFIX_MASK = (0xff << COOKIE_PREFIX_SHIFT)

      COOKIE_PREFIX_DATAPATH       = 0x1
      COOKIE_PREFIX_DP_NETWORK     = 0x2
      COOKIE_PREFIX_DP_ROUTE_LINK  = 0x3
      COOKIE_PREFIX_NETWORK        = 0x4
      COOKIE_PREFIX_PORT           = 0x5
      COOKIE_PREFIX_ROUTE          = 0x6
      COOKIE_PREFIX_ROUTE_LINK     = 0x7
      COOKIE_PREFIX_SERVICE        = 0x8
      COOKIE_PREFIX_SWITCH         = 0x9
      COOKIE_PREFIX_TUNNEL         = 0xa
      COOKIE_PREFIX_VIF            = 0xb
      COOKIE_PREFIX_INTERFACE      = 0xc
      COOKIE_PREFIX_TRANSLATION    = 0xd
      COOKIE_PREFIX_FILTER         = 0xe

      COOKIE_PREFIX_ACTIVE_INTERFACE = 0x10
      COOKIE_PREFIX_ACTIVE_PORT      = 0x11

      # TODO: Reorganize:
      COOKIE_PREFIX_DP_SEGMENT     = 0x13
      COOKIE_PREFIX_SEGMENT        = 0x14
      COOKIE_PREFIX_INTERFACE_SEGMENT = 0x15

      COOKIE_TYPE_DATAPATH       = (COOKIE_PREFIX_DATAPATH << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_DP_NETWORK     = (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_DP_SEGMENT     = (COOKIE_PREFIX_DP_SEGMENT << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_DP_ROUTE_LINK  = (COOKIE_PREFIX_DP_ROUTE_LINK << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_NETWORK        = (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_SEGMENT        = (COOKIE_PREFIX_SEGMENT << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_PORT           = (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_ROUTE          = (COOKIE_PREFIX_ROUTE << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_ROUTE_LINK     = (COOKIE_PREFIX_ROUTE_LINK << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_SERVICE        = (COOKIE_PREFIX_SERVICE << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_SWITCH         = (COOKIE_PREFIX_SWITCH << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_TUNNEL         = (COOKIE_PREFIX_TUNNEL << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_VIF            = (COOKIE_PREFIX_VIF << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_INTERFACE      = (COOKIE_PREFIX_INTERFACE << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_TRANSLATION    = (COOKIE_PREFIX_TRANSLATION << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_FILTER         = (COOKIE_PREFIX_FILTER << COOKIE_PREFIX_SHIFT)

      COOKIE_TYPE_INTERFACE_SEGMENT = (COOKIE_PREFIX_INTERFACE_SEGMENT << COOKIE_PREFIX_SHIFT)

      COOKIE_TYPE_ACTIVE_INTERFACE = (COOKIE_PREFIX_ACTIVE_INTERFACE << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_ACTIVE_PORT      = (COOKIE_PREFIX_ACTIVE_PORT << COOKIE_PREFIX_SHIFT)

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
      METADATA_FLAG_IGNORE_MAC2MAC = (0x100 << METADATA_FLAGS_SHIFT)

      # Allow reflection for this packet, such that if the ingress
      # port is the same as the egress port we will use the
      # 'output:OFPP_IN_PORT' action.
      METADATA_FLAG_REFLECTION = (0x200 << METADATA_FLAGS_SHIFT)

      # Don't pass this packet to the controller, e.g. to look up
      # routing information.
      METADATA_FLAG_NO_CONTROLLER = (0x400 << METADATA_FLAGS_SHIFT)

      METADATA_TYPE_SHIFT      = 56
      METADATA_TYPE_MASK       = (0xff << METADATA_TYPE_SHIFT)

      METADATA_TYPE_DATAPATH        = (0x1 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_DP_ROUTE_LINK   = (0x2 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_NETWORK         = (0x3 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_PORT            = (0x4 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_ROUTE           = (0x5 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_ROUTE_LINK      = (0x6 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_INTERFACE       = (0x7 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_TUNNEL          = (0xa << METADATA_TYPE_SHIFT)
      METADATA_TYPE_DP_NETWORK      = (0xb << METADATA_TYPE_SHIFT)
      METADATA_TYPE_DP_SEGMENT      = (0xc << METADATA_TYPE_SHIFT)

      METADATA_TYPE_SEGMENT         = (0xd << METADATA_TYPE_SHIFT)

      METADATA_VALUE_MASK = 0x7fffffff

      # Special case of the metadata bitfield that allows storing two
      # 31-bit values and one single flag.
      #
      # <64, 63] => 1-bit always true
      # <63, 48] => first 31-bit value
      # <48, 47] => 1-bit flag for any use
      # <47,  0] => second 31-bit value

      METADATA_VALUE_PAIR_TYPE        = (0x1 << 63)
      METADATA_VALUE_PAIR_FLAG        = (0x1 << 31)
      METADATA_VALUE_PAIR_FIRST_MASK  = (0x7fffffff << 32)
      METADATA_VALUE_PAIR_SECOND_MASK = 0x7fffffff

      FLAG_LOCAL = false
      FLAG_REMOTE = true

      #
      # Tunnel constants:
      #

      TUNNEL_ID_MASK    = 0x7fffffff

      TUNNEL_NETWORK    = 0x0
      TUNNEL_ROUTE_LINK = 0x80000000
      TUNNEL_SEGMENT    = 0x80000000

      #
      # 802.1Q constants:
      #

      VLAN_TCI_VID_SHIFT = 12
      VLAN_TCI_DEI = (0x1 << VLAN_TCI_VID_SHIFT)
      VLAN_TCI_MASK_NO_PRIORITY = (0x0fff | VLAN_TCI_DEI)

      #
      # Priorities:
      #

      PRIORITY_FILTER_STATEFUL = 20 + (65 * 66)
      PRIORITY_FILTER_SKIP     = PRIORITY_FILTER_STATEFUL + 1

    end
  end
end
