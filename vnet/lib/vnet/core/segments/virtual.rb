# -*- coding: utf-8 -*-

module Vnet::Core::Segments

  class Virtual < Base

    def mode
      :virtual
    end

    def log_type
      'segment/virtual'
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def flow_tunnel_id
      (@id & TUNNEL_ID_MASK) | TUNNEL_SEGMENT
    end

    def install
      flows = []
      flows << flow_create(table: TABLE_TUNNEL_IDS,
                           goto_table: TABLE_SEGMENT_SRC_CLASSIFIER,
                           match: {
                             :tunnel_id => flow_tunnel_id
                           },
                           priority: 20,
                           write_segment: @id)
      flows << flow_create(table: TABLE_SEGMENT_SRC_CLASSIFIER,
                           goto_table: TABLE_SEGMENT_DST_CLASSIFIER,
                           priority: 30,
                           match_segment: @id)
      flows << flow_create(table: TABLE_SEGMENT_SRC_CLASSIFIER,
                           goto_table: TABLE_SEGMENT_SRC_MAC_LEARNING,
                           priority: 40,
                           match: {
                             :eth_type => 0x0806
                           },
                           match_remote: true,
                           match_segment: @id)
      flows << flow_create(table: TABLE_SEGMENT_DST_CLASSIFIER,
                           goto_table: TABLE_SEGMENT_DST_MAC_LOOKUP,
                           priority: 30,
                           match_segment: @id)

      flows << flow_create(table: TABLE_OUTPUT_DP_TO_CONTROLLER,
                           priority: 1,
                           match_segment: @id,
                           actions: {
                             :output => OFPP_CONTROLLER
                           })

      if @datapath_info.enable_ovs_learn_action
        ovs_flows = []
        ovs_flows << create_ovs_flow_learn_arp(45, "tun_id=0,")
        ovs_flows << create_ovs_flow_learn_arp(5, "", "load:NXM_NX_TUN_ID[]->NXM_NX_TUN_ID[],")
        ovs_flows.each { |flow| @dp_info.add_ovs_flow(flow) }
      else
        # TODO: How correct is it to just catch broadcast packets?
        # Perhaps not needed as the packet should be a return packet
        # so the flow should already have been learned.
        [ [5, {}],
          [45, { tunnel_id: 0 }],
        ].each { |priority, match|
          flows << flow_create(table: TABLE_SEGMENT_SRC_MAC_LEARNING,
                               goto_table: TABLE_OUTPUT_DP_TO_CONTROLLER,
                               priority: priority,
                               match: match.merge(:eth_type => 0x0806),
                               match_segment: @id)
        }

        [ [6, {}],
          [46, { tunnel_id: 0 }],
        ].each { |priority, match|
          flows << flow_create(table: TABLE_SEGMENT_SRC_MAC_LEARNING,
                               priority: priority,
                               match: {
                                 :eth_type => 0x0806,
                                 :eth_dst => MAC_BROADCAST,
                               }.merge(match),
                               match_segment: @id,
                               actions: {
                                 :output => OFPP_CONTROLLER
                               })
        }
      end

      @dp_info.add_flows(flows)
    end

    def update_flows(port_numbers)
      flood_actions = port_numbers.collect { |port_number|
        { :output => port_number }
      }

      flows = []
      flows << Flow.create(TABLE_FLOOD_LOCAL, 1,
                           md_create(:segment => @id),
                           flood_actions, flow_options.merge(:goto_table => TABLE_FLOOD_TUNNELS))

      @dp_info.add_flows(flows)
    end

    def create_ovs_flow_learn_arp(priority, match_options = "", learn_options = "")
      #
      # Work around the current limitations of trema / openflow 1.3 using ovs-ofctl directly.
      #
      match_md = md_create(segment: @id)
      learn_md = md_create(segment: @id, local: nil)

      flow_learn_arp = "table=#{TABLE_SEGMENT_SRC_MAC_LEARNING},priority=#{priority},cookie=0x%x,arp,metadata=0x%x/0x%x,#{match_options}actions=" %
        [@cookie, match_md[:metadata], match_md[:metadata_mask]]
      flow_learn_arp << "learn(table=%d,cookie=0x%x,idle_timeout=36000,priority=35,metadata:0x%x,NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[]," %
        [TABLE_SEGMENT_DST_MAC_LOOKUP, cookie, learn_md[:metadata]]

      flow_learn_arp << learn_options

      flow_learn_arp << "output:NXM_OF_IN_PORT[]),goto_table:%d" % TABLE_SEGMENT_DST_CLASSIFIER
      flow_learn_arp
    end

    def packet_in(message)
      if @datapath_info.enable_ovs_learn_action
        error log_format_h('packet_in however enable_ovs_learn_action is true', in_port: message.in_port, eth_dst: message.eth_dst, eth_src: message.eth_src)
        return
      end

      info log_format_h('packet_in', in_port: message.in_port, eth_dst: message.eth_dst, eth_src: message.eth_src)
      info log_format("packet_in", message.inspect)

      # TODO: Verify eth_src and arp_sha.

      flows = []

      # TODO: Check if match contains tunnel.

      flows << flow_create(table: TABLE_SEGMENT_DST_MAC_LOOKUP,
                           priority: 35,
                           idle_timeout: 36000,
                           match: {
                             :eth_dst => message.eth_src
                           },
                           actions: {
                             :output => message.in_port
                           },
                           match_segment: @id,
                           match_local: nil)
      
      # TODO: Should be possible to also have an idle_timeout if we
      # match in_port(?). The hard_timeout would still be required in
      # the case that the dst_mac_lookup flow times out.

      flows << flow_create(table: TABLE_SEGMENT_SRC_MAC_LEARNING,
                           goto_table: TABLE_SEGMENT_DST_CLASSIFIER,
                           priority: 60,
                           idle_timeout: 60,
                           hard_timeout: 600,
                           match: {
                             :in_port => message.in_port,
                             :eth_src => message.eth_src
                           },
                           match_segment: @id)

      @dp_info.add_flows(flows)

      # TODO: Consider having the controller send the arp packet
      # instead of a direct goto_table so that there won't be any lost
      # packets.

      case message.table_id
      when TABLE_OUTPUT_DP_TO_CONTROLLER
        message.match.in_port = OFPP_CONTROLLER
      when TABLE_SEGMENT_SRC_MAC_LEARNING
      else
        warn log_format("packet in from wrong table", message.inspect)
      end

      @dp_info.send_packet_out(message, OFPP_TABLE)
    end

  end
end
