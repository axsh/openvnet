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

      flow_options = {:cookie => COOKIE_TYPE_SWITCH}
      fo_local_md  = flow_options.merge(md_create(:local => nil))
      fo_remote_md = flow_options.merge(md_create(:remote => nil))

      fo_controller_md = flow_options.merge(md_create(local: nil,
                                                      no_controller: nil))

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
       TABLE_PHYSICAL_SRC,

       TABLE_ROUTE_INGRESS_INTERFACE,
       TABLE_ROUTE_LINK_INGRESS,
       TABLE_ROUTE_LINK_EGRESS,
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

      #
      # Default goto_table flows:
      #

      [[TABLE_ROUTE_INGRESS_INTERFACE, TABLE_NETWORK_DST_CLASSIFIER],
       [TABLE_ROUTE_INGRESS_TRANSLATION, TABLE_ROUTE_LINK_INGRESS],
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

      #
      # Default dynamic load flows:
      #

      [[TABLE_ROUTE_LINK_EGRESS, COOKIE_TYPE_ROUTE_LINK]
      ].each { |table, cookie_type|
        flows << flow_create(:default,
                             table: table,
                             priority: 1,
                             
                             actions: {
                               output: OFPP_CONTROLLER
                             },

                             cookie: cookie_type | COOKIE_DYNAMIC_LOAD_MASK)
      }


      #
      # Default flows:
      #

      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => OFPP_CONTROLLER
                           },
                           nil,
                           fo_controller_md.merge(:goto_table => TABLE_CONTROLLER_PORT))

      flows << Flow.create(TABLE_CLASSIFIER, 1, {:tunnel_id => 0}, nil, flow_options)
      flows << Flow.create(TABLE_CLASSIFIER, 0, {}, nil,
                           fo_remote_md.merge(:goto_table => TABLE_TUNNEL_PORTS))

      # LOCAL packets have already been verified earlier.
      flows << Flow.create(TABLE_VIRTUAL_SRC,  90, md_create(:local => nil), nil,
                           flow_options.merge(:goto_table => TABLE_ROUTE_INGRESS_INTERFACE))
      flows << Flow.create(TABLE_PHYSICAL_SRC,  90, md_create(:local => nil), nil,
                           flow_options.merge(:goto_table => TABLE_ROUTE_INGRESS_INTERFACE))

      flows << Flow.create(TABLE_PHYSICAL_SRC, 40, {:eth_type => 0x0800}, nil, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_SRC, 40, {:eth_type => 0x0806}, nil, flow_options)

      flows << Flow.create(TABLE_VIRTUAL_DST,  30, {:eth_dst => MAC_BROADCAST}, nil,
                           flow_options.merge(:goto_table => TABLE_FLOOD_SIMULATED))
      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {:eth_dst => MAC_BROADCAST}, nil,
                           flow_options.merge(:goto_table => TABLE_FLOOD_SIMULATED))

      flows << Flow.create(TABLE_FLOOD_SEGMENT, 10,
                           md_create(:remote => nil), nil,
                           flow_options)

      flows << Flow.create(TABLE_OUTPUT_CONTROLLER, 0, {}, {:output => OFPP_CONTROLLER}, flow_options)

      flows << flow_create(:default,
                           table: TABLE_OUTPUT_DP_NETWORK_DST,
                           priority: 2,
                           match: {
                             :eth_dst => MAC_BROADCAST
                           })
      flows << flow_create(:default,
                           table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           goto_table: TABLE_OUTPUT_DP_ROUTE_LINK_SET_MAC,
                           priority: 1,
                           match: {
                             :tunnel_id => TUNNEL_ROUTE_LINK
                           })
      flows << flow_create(:default,
                           table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           goto_table: TABLE_OUTPUT_DP_NETWORK_SET_MAC,
                           priority: 1,
                           match: {
                             :tunnel_id => TUNNEL_FLAG,
                             :tunnel_id_mask => TUNNEL_FLAG_MASK
                           })

      # Catches all arp packets that are from local ports.
      #
      # All local ports have the port part of metadata [0,31] zero'ed
      # at this point.
      flows << Flow.create(TABLE_VIRTUAL_SRC, 84,
                           md_create(:local => nil).merge!(:eth_type => 0x0806), nil, flow_options)

      # Next we catch all arp packets, with learning flows for
      # incoming arp packets having been handled by network/eth_port
      # specific flows.
      flows << Flow.create(TABLE_VIRTUAL_SRC, 82, {
                             :eth_type => 0x0806,
                             :tunnel_id => 0,
                           }, nil, flow_options)

      flows << Flow.create(TABLE_VIRTUAL_SRC, 80, {
                             :eth_type => 0x0806,
                           }, nil, flow_options)

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
