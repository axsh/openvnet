# -*- Coding: utf-8 -*-

module Vnet::Core::Networks

  class Virtual < Base

    def network_type
      :virtual
    end

    def log_type
      'network/virtual'
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def flow_tunnel_id
      (@id & TUNNEL_ID_MASK) | TUNNEL_NETWORK
    end

    def install
      flows = []
      flows << flow_create(table: TABLE_TUNNEL_IDS,
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER,
                           match: {
                             :tunnel_id => flow_tunnel_id
                           },
                           priority: 20,
                           write_network: @id)
      flows << flow_create(table: TABLE_NETWORK_SRC_CLASSIFIER,
                           goto_table: TABLE_ROUTE_INGRESS_INTERFACE,
                           priority: 30,
                           match_network: @id)
      flows << flow_create(table: TABLE_NETWORK_SRC_CLASSIFIER,
                           goto_table: TABLE_NETWORK_SRC_MAC_LEARNING,
                           priority: 40,
                           match: {
                             :eth_type => 0x0806
                           },
                           match_remote: true,
                           match_network: @id)
      flows << flow_create(table: TABLE_NETWORK_DST_CLASSIFIER,
                           goto_table: TABLE_NETWORK_DST_MAC_LOOKUP,
                           priority: 30,
                           match_network: @id)

      ovs_flows = []

      if @segment_id
        subnet_dst = match_ipv4_subnet_dst(@ipv4_network, @ipv4_prefix)
        subnet_src = match_ipv4_subnet_src(@ipv4_network, @ipv4_prefix)

        flows << flow_create(table: TABLE_SEGMENT_SRC_CLASSIFIER,
                             goto_table: TABLE_NETWORK_CONNECTION,
                             priority: 50 + flow_priority,
                             match: subnet_dst,
                             match_segment: @segment_id,
                             write_network: @id)

        # TODO: ??????????? This should be for _all_ networks.
        flows << flow_create(table: TABLE_NETWORK_DST_CLASSIFIER,
                             goto_table: TABLE_FLOOD_SIMULATED,
                             priority: 31,
                             match: {
                               :eth_dst => MAC_BROADCAST
                             },
                             match_network: @id,
                             write_segment: @segment_id)

        flows << flow_create(table: TABLE_NETWORK_DST_MAC_LOOKUP,
                             goto_table: TABLE_SEGMENT_DST_CLASSIFIER,
                             priority: 25,
                             match_network: @id,
                             write_segment: @segment_id)
      end

      @dp_info.add_flows(flows)

      ovs_flows << create_ovs_flow_learn_arp(3, "tun_id=0,")
      ovs_flows << create_ovs_flow_learn_arp(1, "", "load:NXM_NX_TUN_ID[]->NXM_NX_TUN_ID[],")
      ovs_flows.each { |flow| @dp_info.add_ovs_flow(flow) }
    end

    def update_flows(port_numbers)
      flood_actions = port_numbers.collect { |port_number|
        { :output => port_number }
      }

      flows = []
      flows << Flow.create(TABLE_FLOOD_LOCAL, 1,
                           md_create(:network => @id),
                           flood_actions, flow_options.merge(:goto_table => TABLE_FLOOD_TUNNELS))

      @dp_info.add_flows(flows)
    end

    def create_ovs_flow_learn_arp(priority, match_options = "", learn_options = "")
      #
      # Work around the current limitations of trema / openflow 1.3 using ovs-ofctl directly.
      #
      match_network_md = md_create(network: @id)

      flow_learn_arp = "table=%d,priority=%d,cookie=0x%x,arp,metadata=0x%x/0x%x,%sactions=" %
        [TABLE_NETWORK_SRC_MAC_LEARNING, priority, @cookie, match_network_md[:metadata], match_network_md[:metadata_mask], match_options]

      [md_create(match_network: @id, match_local: nil),
       md_create(network: @id, match_reflection: true)
      ].each { |metadata|
        flow_learn_arp << "learn(table=%d,cookie=0x%x,idle_timeout=36000,priority=35,metadata:0x%x,NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[]," %
          [TABLE_NETWORK_DST_MAC_LOOKUP, cookie, metadata[:metadata]]
        flow_learn_arp << learn_options
        flow_learn_arp << "output:NXM_OF_IN_PORT[]),"
      }

      if @segment_id
        learn_segment_md = md_create(segment: @id, local: nil)

        flow_learn_arp << ",learn(table=%d,cookie=0x%x,idle_timeout=36000,priority=35,metadata:0x%x,NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[]," %
          [TABLE_SEGMENT_DST_MAC_LOOKUP, cookie, learn_segment_md[:metadata]]

        flow_learn_arp << learn_options
        flow_learn_arp << "output:NXM_OF_IN_PORT[]),"
      end

      flow_learn_arp << "goto_table:%d" % TABLE_NETWORK_DST_CLASSIFIER
      flow_learn_arp
    end

  end
end
