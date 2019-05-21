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
      flows << flow_create(table: TABLE_TUNNEL_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                           priority: 20,

                           match: {
                             :tunnel_id => flow_tunnel_id
                           },

                           write_reflection: false,
                           write_second: @id,
                          )
      flows << flow_create(table: TABLE_NETWORK_SRC_CLASSIFIER_NW_NIL,
                           goto_table: TABLE_ROUTE_INGRESS_INTERFACE_NW_NIL,
                           priority: 30,

                           match_first: @id,
                          )
      flows << flow_create(table: TABLE_NETWORK_DST_CLASSIFIER_NW_NIL,
                           goto_table: TABLE_NETWORK_DST_MAC_LOOKUP_NIL_NW,
                           priority: 30,

                           match_first: @id,
                           write_first: 0,
                           write_second: @id,
                          )

      ovs_flows = []

      if @segment_id
        subnet_dst = match_ipv4_subnet_dst(@ipv4_network, @ipv4_prefix)
        subnet_src = match_ipv4_subnet_src(@ipv4_network, @ipv4_prefix)

        flows << flow_create(table: TABLE_SEGMENT_SRC_CLASSIFIER_SEG_NIL,
                             goto_table: TABLE_NETWORK_SRC_CLASSIFIER_NW_NIL,
                             priority: 50 + flow_priority,

                             match: subnet_dst,
                             match_first: @segment_id,
                             write_first: @id,
                            )
        # TODO: ??????????? This should be for _all_ networks.
        flows << flow_create(table: TABLE_NETWORK_DST_CLASSIFIER_NW_NIL,
                             goto_table: TABLE_FLOOD_SIMULATED_SEG_NW,
                             priority: 31,

                             match: {
                               destination_mac_address: MAC_BROADCAST
                             },
                             match_first: @id,
                             
                             write_first: @segment_id,
                             write_second: @id,
                            )
        flows << flow_create(table: TABLE_NETWORK_DST_MAC_LOOKUP_NIL_NW,
                             goto_table: TABLE_SEGMENT_DST_CLASSIFIER_SEG_NW,
                             priority: 25,

                             match_second: @id,
                             write_first: @segment_id,
                            )
      end

      @dp_info.add_flows(flows)
    end

    def update_flows(port_numbers)
      flow_actions = port_numbers.collect { |port_number|
        { output: port_number }
      }

      flows = []
      flows << flow_create(table: TABLE_FLOOD_LOCAL_SEG_NW,
                           goto_table: TABLE_FLOOD_TUNNELS_SEG_NW,
                           priority: 1,
                           
                           match_second: @id,

                           actions: flow_actions)

      @dp_info.add_flows(flows)
    end

  end
end
