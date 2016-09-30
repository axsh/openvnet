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

      @dp_info.add_flows(flows)

      ovs_flows = []
      ovs_flows << create_ovs_flow_learn_arp(45, "tun_id=0,")
      ovs_flows << create_ovs_flow_learn_arp(5, "", "load:NXM_NX_TUN_ID[]->NXM_NX_TUN_ID[],")
      ovs_flows.each { |flow| @dp_info.add_ovs_flow(flow) }
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

  end
end
