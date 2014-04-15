# -*- coding: utf-8 -*-

module Vnet
  module Constants
    module OpenflowFlows

      #
      # OpenFlow tables:
      #

      # Default table used by all incoming packets.
      TABLE_CLASSIFIER = 0

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

      # Handle ingress packets to host interfaces from untrusted
      # sources.
      TABLE_INTERFACE_INGRESS_CLASSIFIER = 10
      TABLE_INTERFACE_INGRESS_MAC        = 11
      TABLE_INTERFACE_INGRESS_NW_IF      = 12
      TABLE_INTERFACE_INGRESS_ROUTE_LINK = 13

      # Handle egress packets from trusted interfaces.
      TABLE_INTERFACE_EGRESS_CLASSIFIER  = 15
      TABLE_INTERFACE_EGRESS_ROUTES      = 16
      TABLE_INTERFACE_EGRESS_MAC         = 17
      TABLE_INTERFACE_EGRESS_FILTER      = 18

      # Initial verification of network number and application of global
      # filtering rules.
      #
      # The network number stored in bits [32,48> are used to identify
      # the network, and zero is assumped to be destined for what is
      # currently known as the 'physical' network.
      #
      # Later we will always require a network number to be supplied.
      TABLE_NETWORK_SRC_CLASSIFIER    = 20
      TABLE_NETWORK_SRC_MAC_LEARNING  = 21

      # In the transition from TABLE_ROUTER_EGRESS_LOOKUP to
      # TABLE_ROUTE_EGRESS_LOOKUP the packet loses it's metadata flags.
      TABLE_ROUTE_INGRESS_INTERFACE          = 30
      TABLE_ROUTE_INGRESS_TRANSLATION        = 31
      TABLE_ROUTER_INGRESS_LOOKUP            = 32
      TABLE_ROUTER_CLASSIFIER                = 33
      TABLE_ROUTER_EGRESS_LOOKUP             = 34
      TABLE_ROUTE_EGRESS_LOOKUP              = 35
      TABLE_ROUTE_EGRESS_TRANSLATION         = 36
      TABLE_ROUTE_EGRESS_INTERFACE           = 37

      TABLE_ARP_TABLE                        = 40
      TABLE_ARP_LOOKUP                       = 41

      TABLE_NETWORK_DST_CLASSIFIER           = 42
      TABLE_NETWORK_DST_MAC_LOOKUP           = 43

      TABLE_INTERFACE_INGRESS_FILTER         = 45
      TABLE_INTERFACE_INGRESS_FILTER_LOOKUP  = 46

      TABLE_FLOOD_SIMULATED                  = 50
      TABLE_FLOOD_LOCAL                      = 51
      TABLE_FLOOD_TUNNELS                    = 52
      TABLE_FLOOD_SEGMENT                    = 53

      TABLE_LOOKUP_IF_NW_TO_DP_NW            = 70
      TABLE_LOOKUP_IF_RL_TO_DP_RL            = 71
      TABLE_LOOKUP_DP_NW_TO_DP_NETWORK       = 72
      TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK    = 73
      TABLE_LOOKUP_NETWORK_TO_HOST_IF_EGRESS = 74

      # The 'output dp * lookup' tables use the DatapathNetwork and
      # DatapathRouteLink database entry keys to determine what source
      # interface and destination interfaces should be used for
      # packets.
      #
      # For MAC2MAC this only requires changing the destionation MAC
      # address to the one associated with that particular datapath
      # network or route link, while for tunnels the output port needs
      # to be selected from pre-created tunnels.

      TABLE_OUTPUT_DP_NETWORK_DST_IF         = 80
      TABLE_OUTPUT_DP_NETWORK_SRC_IF         = 81

      TABLE_OUTPUT_DP_ROUTE_LINK_DST_IF      = 82
      TABLE_OUTPUT_DP_ROUTE_LINK_SRC_IF      = 84

      TABLE_OUTPUT_DP_OVER_MAC2MAC           = 85 # Match src/dst if id, output if present.
      TABLE_OUTPUT_DP_OVER_TUNNEL            = 86 # Use tun_id to determine type for goto_table.

      #
      # Output ports tables:
      #

      # Directly output to a port type with no additional
      # actions. Usable by any table and as such need to be the last
      # tables.
      TABLE_OUT_PORT_INTERFACE_INGRESS = 90
      TABLE_OUT_PORT_INTERFACE_EGRESS  = 91
      TABLE_OUT_PORT_TUNNEL            = 92

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
      COOKIE_PREFIX_CONNECTION     = 0xf

      COOKIE_TYPE_CONNECTION     = (COOKIE_PREFIX_CONNECTION << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_DATAPATH       = (COOKIE_PREFIX_DATAPATH << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_DP_NETWORK     = (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_DP_ROUTE_LINK  = (COOKIE_PREFIX_DP_ROUTE_LINK << COOKIE_PREFIX_SHIFT)
      COOKIE_TYPE_NETWORK        = (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)
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
      METADATA_TYPE_EDGE_TO_VIRTUAL = (0x8 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_VIRTUAL_TO_EDGE = (0x9 << METADATA_TYPE_SHIFT)
      METADATA_TYPE_TUNNEL          = (0xa << METADATA_TYPE_SHIFT)
      METADATA_TYPE_DP_NETWORK      = (0xb << METADATA_TYPE_SHIFT)

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

      #
      # Tunnel constants:
      #

      TUNNEL_FLAG = (0x1 << 31)
      TUNNEL_FLAG_MASK = 0x80000000
      TUNNEL_NETWORK_MASK = 0x7fffffff

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
