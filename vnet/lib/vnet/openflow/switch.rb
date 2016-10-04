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

      [TABLE_EDGE_SRC,
       TABLE_EDGE_DST,
       TABLE_TUNNEL_PORTS,
       TABLE_TUNNEL_IDS,
       TABLE_LOCAL_PORT,
       TABLE_CONTROLLER_PORT,
       TABLE_PROMISCUOUS_PORT,

       TABLE_INTERFACE_INGRESS_CLASSIFIER,
       TABLE_INTERFACE_INGRESS_MAC,
       TABLE_INTERFACE_INGRESS_SEG_IF,
       TABLE_INTERFACE_INGRESS_NW_IF,
       TABLE_INTERFACE_INGRESS_ROUTE_LINK,

       TABLE_INTERFACE_INGRESS_FILTER_LOOKUP,

       TABLE_INTERFACE_EGRESS_CLASSIFIER,
       TABLE_INTERFACE_EGRESS_FILTER,
       TABLE_INTERFACE_EGRESS_VALIDATE,
       TABLE_INTERFACE_EGRESS_ROUTES,
       TABLE_INTERFACE_EGRESS_MAC,

       TABLE_SEGMENT_SRC_CLASSIFIER,
       TABLE_NETWORK_SRC_CLASSIFIER,

       TABLE_ROUTE_INGRESS_INTERFACE,
       TABLE_ROUTE_INGRESS_TRANSLATION,
       TABLE_ROUTER_INGRESS_LOOKUP,
       TABLE_ROUTER_CLASSIFIER,
       TABLE_ROUTER_EGRESS_LOOKUP,
       TABLE_ROUTE_EGRESS_LOOKUP,
       TABLE_ROUTE_EGRESS_TRANSLATION,
       TABLE_ROUTE_EGRESS_INTERFACE,
       TABLE_ARP_LOOKUP,

       TABLE_NETWORK_DST_CLASSIFIER,
       TABLE_NETWORK_DST_MAC_LOOKUP,
       TABLE_SEGMENT_DST_CLASSIFIER,
       TABLE_SEGMENT_DST_MAC_LOOKUP,

       TABLE_FLOOD_LOCAL,
       TABLE_FLOOD_SEGMENT,

       TABLE_LOOKUP_IF_NW_TO_DP_NW,
       TABLE_LOOKUP_IF_RL_TO_DP_RL,
       TABLE_LOOKUP_DP_NW_TO_DP_NETWORK,
       TABLE_LOOKUP_DP_SEG_TO_DP_SEGMENT,
       TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK,
       TABLE_LOOKUP_NETWORK_TO_HOST_IF_EGRESS,
       TABLE_LOOKUP_SEGMENT_TO_HOST_IF_EGRESS,

       TABLE_OUTPUT_DP_NETWORK_DST_IF,
       TABLE_OUTPUT_DP_NETWORK_SRC_IF,
       TABLE_OUTPUT_DP_SEGMENT_DST_IF,
       TABLE_OUTPUT_DP_SEGMENT_SRC_IF,
       TABLE_OUTPUT_DP_ROUTE_LINK_DST_IF,
       TABLE_OUTPUT_DP_ROUTE_LINK_SRC_IF,

       TABLE_OUTPUT_DP_OVER_TUNNEL,

       TABLE_OUT_PORT_INTERFACE_INGRESS,
       TABLE_OUT_PORT_INTERFACE_EGRESS,
       TABLE_OUT_PORT_TUNNEL,

      ].each { |table|
        flows << flow_create(table: table, priority: 0)
      }

      [[TABLE_CLASSIFIER, 1, nil, { :tunnel_id => 0 }],
       [TABLE_FLOOD_TUNNELS, 10, :match_remote, nil],
       [TABLE_OUTPUT_DP_NETWORK_DST_IF, 2, nil, { :eth_dst => MAC_BROADCAST }],
       [TABLE_OUTPUT_DP_OVER_MAC2MAC, 1, nil, { :tunnel_id => 0 }],
      ].each { |table, priority, flag, match|
        flows << flow_create({ table: table,
                               priority: priority,
                               match: match,
                               flag => true
                             })
      }

      #
      # Default goto_table flows:
      #
      [[TABLE_SEGMENT_SRC_MAC_LEARNING, TABLE_SEGMENT_DST_CLASSIFIER],
       [TABLE_NETWORK_CONNECTION, TABLE_NETWORK_SRC_CLASSIFIER],
       [TABLE_NETWORK_SRC_MAC_LEARNING, TABLE_NETWORK_DST_CLASSIFIER],        
       [TABLE_ROUTE_INGRESS_INTERFACE, TABLE_NETWORK_DST_CLASSIFIER],
       [TABLE_ARP_TABLE, TABLE_ARP_LOOKUP],
       [TABLE_FLOOD_SIMULATED, TABLE_FLOOD_LOCAL],
       [TABLE_FLOOD_TUNNELS, TABLE_FLOOD_SEGMENT],
       [TABLE_INTERFACE_INGRESS_FILTER, TABLE_INTERFACE_INGRESS_FILTER_LOOKUP],
       [TABLE_OUTPUT_DP_OVER_MAC2MAC, TABLE_OUTPUT_DP_OVER_TUNNEL],
      ].each { |from_table, to_table|
        flows << flow_create(table: from_table,
                             goto_table: to_table,
                             priority: 0)
      }

      [[TABLE_CLASSIFIER, TABLE_TUNNEL_PORTS, 0, :write_remote, nil],
       [TABLE_SEGMENT_SRC_MAC_LEARNING, TABLE_SEGMENT_DST_CLASSIFIER, 44, nil, {
          :eth_type => 0x0806,
          :tunnel_id => 0
        }],
       [TABLE_NETWORK_SRC_MAC_LEARNING, TABLE_NETWORK_DST_CLASSIFIER, 2, nil, {
          :eth_type => 0x0806,
          :tunnel_id => 0
        }],
       [TABLE_NETWORK_DST_MAC_LOOKUP, TABLE_FLOOD_SIMULATED, 30, nil, {
          :eth_dst => MAC_BROADCAST
        }],
       [TABLE_SEGMENT_DST_MAC_LOOKUP, TABLE_FLOOD_SIMULATED, 30, nil, {
          :eth_dst => MAC_BROADCAST
        }],
      ].each { |from_table, to_table, priority, flag, match|
        flows << flow_create({ table: from_table,
                               goto_table: to_table,
                               priority: priority,
                               match: match,
                               flag => true
                             })
      }

      #
      # Default classifier flows:
      #
      flows << flow_create(table: TABLE_CLASSIFIER,
                           goto_table: TABLE_LOCAL_PORT,
                           priority: 2,
                           match: {
                             :in_port => OFPP_LOCAL
                           },
                           write_local: true)
      flows << flow_create(table: TABLE_CLASSIFIER,
                           goto_table: TABLE_CONTROLLER_PORT,
                           priority: 2,
                           match: {
                             :in_port => OFPP_CONTROLLER
                           },
                           write_local: true,
                           write_no_controller: true)

      #
      # Default dynamic load flows:
      #
      [#[TABLE_ROUTER_CLASSIFIER, COOKIE_TYPE_ROUTE_LINK]
      ].each { |table, cookie_type|
        flows << flow_create(table: table,
                             priority: 1,

                             actions: {
                               output: OFPP_CONTROLLER
                             },

                             cookie: cookie_type | COOKIE_DYNAMIC_LOAD_MASK)
      }

      @dp_info.add_flows(flows)
    end

    #
    # Send messages that will start initializing the switch.
    #
    def switch_ready
      @dp_info.send_message(Trema::Messages::FeaturesRequest.new)
      @dp_info.send_message(Trema::Messages::PortDescMultipartRequest.new)
    end

    def features_reply(message)
      debug log_format("transaction_id: %#x" % message.transaction_id)
      debug log_format("n_buffers: %u" % message.n_buffers)
      debug log_format("n_tables: %u" % message.n_tables)
      debug log_format("capabilities: %u" % message.capabilities)
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

    def update_vlan_translation
      # TODO: This should be removed.
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
