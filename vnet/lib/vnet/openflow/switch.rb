# -*- coding: utf-8 -*-

require 'celluloid'

module Vnet::Openflow

  class Switch
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Dispatchable

    def initialize(dp, name = nil)
      @datapath = dp || raise("cannot create a Switch object without a valid datapath")
      @dp_info = dp.dp_info

      @dpid = @datapath.dpid
      @dpid_s = "0x%016x" % @datapath.dpid
    end

    def cookie
      COOKIE_TYPE_SWITCH
    end

    #
    # Event handlers:
    #

    def create_default_flows
      #
      # Add default flows:
      #

      flows = []

      #
      # Default drop flows:
      #

      [TABLE_LOCAL_PORT,
       TABLE_CONTROLLER_PORT,
       TABLE_TUNNEL_IF_NIL,
       
       TABLE_INTERFACE_INGRESS_CLASSIFIER_IF_NIL,
       TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
       TABLE_INTERFACE_INGRESS_IF_SEG,
       TABLE_INTERFACE_INGRESS_SEG_DPSEG,
       TABLE_INTERFACE_INGRESS_IF_NW,
       TABLE_INTERFACE_INGRESS_NW_DPNW,
       TABLE_INTERFACE_INGRESS_RL_DPRL,

       TABLE_INTERFACE_INGRESS_FILTER_LOOKUP_IF_NIL,

       TABLE_INTERFACE_EGRESS_CLASSIFIER_IF_NIL,
       TABLE_INTERFACE_EGRESS_FILTER_IF_NIL,
       TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL,
       TABLE_INTERFACE_EGRESS_ROUTES_IF_NIL,
       TABLE_INTERFACE_EGRESS_ROUTES_IF_NW,

       TABLE_SEGMENT_SRC_CLASSIFIER_SEG_NIL,
       TABLE_NETWORK_SRC_CLASSIFIER_NW_NIL,

       TABLE_ROUTE_INGRESS_INTERFACE_NW_NIL,
       TABLE_ROUTE_INGRESS_TRANSLATION_IF_NIL,
       TABLE_ROUTER_INGRESS_LOOKUP_IF_NIL,
       TABLE_ROUTER_CLASSIFIER_RL_NIL,
       TABLE_ROUTER_EGRESS_LOOKUP_RL_NIL,
       TABLE_ROUTE_EGRESS_LOOKUP_IF_RL,
       TABLE_ROUTE_EGRESS_TRANSLATION_IF_NIL,
       TABLE_ROUTE_EGRESS_INTERFACE_IF_NIL,
       TABLE_ARP_LOOKUP_NW_NIL,

       TABLE_NETWORK_DST_CLASSIFIER_NW_NIL,
       TABLE_NETWORK_DST_MAC_LOOKUP_NIL_NW,
       TABLE_SEGMENT_DST_CLASSIFIER_SEG_NW,
       TABLE_SEGMENT_DST_MAC_LOOKUP_SEG_NW,

       TABLE_FLOOD_LOCAL_SEG_NW,
       TABLE_FLOOD_SEGMENT_SEG_NW,

       TABLE_LOOKUP_IF_NW,
       TABLE_LOOKUP_IF_RL,
       TABLE_LOOKUP_DP_NW,
       TABLE_LOOKUP_DP_SEG,
       TABLE_LOOKUP_DP_RL,
       TABLE_LOOKUP_NW_NIL,
       TABLE_LOOKUP_SEG_NIL,

       TABLE_OUTPUT_HOSTIF_DST_DPN_NIL,
       TABLE_OUTPUT_HOSTIF_DST_DPS_NIL,
       TABLE_OUTPUT_HOSTIF_DST_DPR_NIL,
       TABLE_OUTPUT_HOSTIF_SRC_NW_DIF,
       TABLE_OUTPUT_HOSTIF_SRC_SEG_DIF,
       TABLE_OUTPUT_HOSTIF_SRC_RL_DIF,

       TABLE_OUTPUT_TUNNEL_SIF_DIF,
       TABLE_OUTPUT_CONTROLLER_SEG_NW,

       TABLE_OUT_PORT_INGRESS_IF_NIL,
       TABLE_OUT_PORT_EGRESS_IF_NIL,
       TABLE_OUT_PORT_EGRESS_TUN_NIL,

      ].each { |table|
        flows << flow_create(table: table, priority: 0)
      }

      [[TABLE_CLASSIFIER, 10, nil, { :tunnel_id => 0 }],
       [TABLE_OUTPUT_HOSTIF_DST_DPN_NIL, 2, nil, { :eth_dst => MAC_BROADCAST }],
       [TABLE_OUTPUT_MAC2MAC_SIF_DIF, 1, nil, { :tunnel_id => 0 }],
      ].each { |table, priority, flag, match|
        flows << flow_create({ table: table,
                               priority: priority,
                               match: match,
                               flag => true
                             })
      }

      flows << flow_create(table: TABLE_FLOOD_TUNNELS_SEG_NW,
                           priority: 10,
                           match_remote: true,
                          )

      #
      # Default goto_table flows:
      #
      [[TABLE_INTERFACE_EGRESS_STATEFUL_IF_NIL, TABLE_INTERFACE_EGRESS_FILTER_IF_NIL],
       [TABLE_ROUTE_INGRESS_INTERFACE_NW_NIL, TABLE_NETWORK_DST_CLASSIFIER_NW_NIL],
       [TABLE_ARP_TABLE_NW_NIL, TABLE_ARP_LOOKUP_NW_NIL],
       [TABLE_FLOOD_SIMULATED_SEG_NW, TABLE_FLOOD_LOCAL_SEG_NW],
       [TABLE_FLOOD_TUNNELS_SEG_NW, TABLE_FLOOD_SEGMENT_SEG_NW],
       [TABLE_INTERFACE_INGRESS_FILTER_IF_NIL, TABLE_INTERFACE_INGRESS_FILTER_LOOKUP_IF_NIL],
       [TABLE_OUTPUT_MAC2MAC_SIF_DIF, TABLE_OUTPUT_TUNNEL_SIF_DIF],
      ].each { |from_table, to_table|
        flows << flow_create(table: from_table,
                             goto_table: to_table,
                             priority: 0)
      }

      [[TABLE_NETWORK_DST_MAC_LOOKUP_NIL_NW, TABLE_FLOOD_SIMULATED_SEG_NW],
       [TABLE_SEGMENT_DST_MAC_LOOKUP_SEG_NW, TABLE_FLOOD_SIMULATED_SEG_NW],
      ].each { |from_table, to_table, priority, match|
        flows << flow_create(table: from_table,
                             goto_table: to_table,
                             priority: 30,
                             match: {
                               eth_dst: MAC_BROADCAST
                             })
      }

      #
      # Default classifier flows:
      #
      flows << flow_create(table: TABLE_CLASSIFIER,
                           goto_table: TABLE_LOCAL_PORT,
                           priority: 12,
                           match: {
                             in_port: Pio::OpenFlow13::Port32.reserved_port_number(:local)
                           })
      flows << flow_create(table: TABLE_CLASSIFIER,
                           goto_table: TABLE_CONTROLLER_PORT,
                           priority: 12,
                           match: {
                             in_port: Pio::OpenFlow13::Port32.reserved_port_number(:controller)
                           })

      #
      # Default dynamic load flows:
      #
      [#[TABLE_ROUTER_CLASSIFIER_RL_NIL, COOKIE_TYPE_ROUTE_LINK]
      ].each { |table, cookie_type|
        flows << flow_create(table: table,
                             priority: 1,

                             actions: {
                               output: :controller
                             },

                             cookie: cookie_type | COOKIE_DYNAMIC_LOAD_MASK)
      }

      @dp_info.add_flows(flows)
    end

    #
    # Send messages that will start initializing the switch.
    #
    def switch_ready
      @dp_info.send_message(Pio::OpenFlow13::Features::Request.new)
      # @dp_info.send_message(Pio::OpenFlow13::PortDescMultipart::Request.new)
    end

    def features_reply(message)
      debug log_format("transaction_id: %#x" % message.transaction_id)
      debug log_format("n_buffers: %u" % message.n_buffers)
      debug log_format("n_tables: %u" % message.n_tables)
      debug log_format("capabilities: #{message.capabilities.join(', ')}")
    end

    def port_status(message)
      debug log_format("port_status #{message.name}",
                       "reason:#{message.reason} port_no:#{message.port_no} " +
                       "hw_addr:#{message.hw_addr} state:%#x" % message.state)

      case message.reason
      when OFPPR_ADD
        debug log_format("adding port")
        @dp_info.port_manager.insert(message)
      when OFPPR_DELETE
        debug log_format("deleting port")
        @dp_info.port_manager.remove(message)
      end
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} switch: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
