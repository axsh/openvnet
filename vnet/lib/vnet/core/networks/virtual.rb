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
                           goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                           priority: 20,

                           match: {
                             :tunnel_id => flow_tunnel_id
                           },

                           write_value_pair_flag: FLAG_REMOTE,
                           write_value_pair_second: @id,
                          )
      flows << flow_create(table: TABLE_NETWORK_SRC_CLASSIFIER,
                           goto_table: TABLE_ROUTE_INGRESS_INTERFACE,
                           priority: 30,
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

  end
end
