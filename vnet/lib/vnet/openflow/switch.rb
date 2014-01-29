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
       TABLE_TUNNEL_NETWORK_IDS,
       TABLE_LOCAL_PORT,
       TABLE_CONTROLLER_PORT,

       TABLE_INTERFACE_INGRESS_CLASSIFIER,
       TABLE_INTERFACE_INGRESS_MAC,
       TABLE_INTERFACE_INGRESS_NW_IF,
       TABLE_INTERFACE_INGRESS_FILTER_LOOKUP,
       TABLE_INTERFACE_EGRESS_CLASSIFIER,
       TABLE_INTERFACE_EGRESS_ROUTES,
       TABLE_INTERFACE_EGRESS_MAC,

       TABLE_NETWORK_SRC_CLASSIFIER,
       TABLE_NETWORK_DST_CLASSIFIER,
       TABLE_VIRTUAL_SRC,

       TABLE_ROUTE_INGRESS_INTERFACE,
       TABLE_ROUTER_INGRESS,
       TABLE_ROUTER_CLASSIFIER,
       TABLE_ROUTER_EGRESS,
       TABLE_ROUTE_EGRESS_LOOKUP,
       TABLE_ROUTE_EGRESS_INTERFACE,
       TABLE_ARP_LOOKUP,

       TABLE_VIRTUAL_DST,
       TABLE_PHYSICAL_DST,
       TABLE_FLOOD_LOCAL,
       TABLE_FLOOD_TUNNELS,

       TABLE_LOOKUP_IF_NW_TO_DP_NW,
       TABLE_LOOKUP_IF_RL_TO_DP_RL,
       TABLE_LOOKUP_DP_NW_TO_DP_NETWORK,
       TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK,

       TABLE_OUTPUT_DP_NETWORK_DST,
       TABLE_OUTPUT_DP_NETWORK_SRC,
       TABLE_OUTPUT_DP_ROUTE_LINK_DST,
       TABLE_OUTPUT_DP_ROUTE_LINK_SRC,

       TABLE_OUTPUT_DP_OVER_MAC2MAC,
       TABLE_OUTPUT_DP_ROUTE_LINK_SET_MAC,
       TABLE_OUTPUT_DP_OVER_TUNNEL,

       TABLE_OUT_PORT_INTERFACE_INGRESS,
       TABLE_OUT_PORT_INTERFACE_EGRESS,
       TABLE_OUT_PORT_TUNNEL,

      ].each { |table|
        flows << flow_create(:default, table: table, priority: 0)
      }

      [[TABLE_CLASSIFIER, 1, nil, { :tunnel_id => 0 }],
       [TABLE_VIRTUAL_SRC, 84, :match_local, { :eth_type => 0x0806 }],
       [TABLE_VIRTUAL_SRC, 82, nil, { :eth_type => 0x0806, :tunnel_id => 0 }],
       [TABLE_VIRTUAL_SRC, 80, nil, { :eth_type => 0x0806 }],
       [TABLE_FLOOD_SEGMENT, 10, :match_remote, nil],
       [TABLE_OUTPUT_DP_NETWORK_DST, 2, nil, { :eth_dst => MAC_BROADCAST }],
      ].each { |table, priority, flag, match|
        flows << flow_create(:default, {
                               table: table,
                               priority: priority,
                               match: match,
                               flag => true
                             })
      }

      #
      # Default goto_table flows:
      #
      [[TABLE_ROUTE_INGRESS_INTERFACE, TABLE_NETWORK_DST_CLASSIFIER],
       [TABLE_ROUTE_INGRESS_TRANSLATION, TABLE_ROUTER_INGRESS],
       [TABLE_ROUTE_EGRESS_TRANSLATION, TABLE_ROUTE_EGRESS_INTERFACE],
       [TABLE_ARP_TABLE, TABLE_ARP_LOOKUP],
       [TABLE_OUTPUT_DP_NETWORK_SET_MAC, TABLE_OUTPUT_DP_OVER_TUNNEL],
       [TABLE_FLOOD_SIMULATED, TABLE_FLOOD_LOCAL],
       [TABLE_FLOOD_SEGMENT, TABLE_FLOOD_TUNNELS],
       [TABLE_INTERFACE_EGRESS_FILTER, TABLE_NETWORK_SRC_CLASSIFIER],
       [TABLE_INTERFACE_INGRESS_FILTER, TABLE_INTERFACE_INGRESS_FILTER_LOOKUP],
      ].each { |from_table, to_table|
        flows << flow_create(:default,
                             table: from_table,
                             goto_table: to_table,
                             priority: 0)
      }

      [[TABLE_CLASSIFIER, TABLE_TUNNEL_PORTS, 0, :write_remote, nil],
       [TABLE_VIRTUAL_SRC, TABLE_ROUTE_INGRESS_INTERFACE, 90, :match_local, nil],
       [TABLE_VIRTUAL_DST, TABLE_FLOOD_SIMULATED, 30, nil, { :eth_dst => MAC_BROADCAST }],
       [TABLE_PHYSICAL_DST, TABLE_FLOOD_SIMULATED, 30, nil, { :eth_dst => MAC_BROADCAST }],
       [TABLE_OUTPUT_DP_OVER_MAC2MAC, TABLE_OUTPUT_DP_ROUTE_LINK_SET_MAC, 1, nil, {
          :tunnel_id => TUNNEL_ROUTE_LINK
        }],
       [TABLE_OUTPUT_DP_OVER_MAC2MAC, TABLE_OUTPUT_DP_NETWORK_SET_MAC, 1, nil, {
          :tunnel_id => TUNNEL_FLAG,
          :tunnel_id_mask => TUNNEL_FLAG_MASK
        }],
      ].each { |from_table, to_table, priority, flag, match|
        flows << flow_create(:default, {
                               table: from_table,
                               goto_table: to_table,
                               priority: priority,
                               match: match,
                               flag => true
                             })
      }

      flows << flow_create(:default,
                           table: TABLE_CLASSIFIER,
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
        flows << flow_create(:default,
                             table: table,
                             priority: 1,
                             
                             actions: {
                               output: OFPP_CONTROLLER
                             },

                             cookie: cookie_type | COOKIE_DYNAMIC_LOAD_MASK)
      }

      @datapath.add_flows(flows)
    end

    def switch_ready
      #
      # Send messages that will start initializing the switch.
      #
      @datapath.send_message(Trema::Messages::FeaturesRequest.new)
      @datapath.send_message(Trema::Messages::PortDescMultipartRequest.new)

      # Temporary hack to load the public network.
      @dp_info.network_manager.async.item(uuid: 'nw-public')
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
      # TODO
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
