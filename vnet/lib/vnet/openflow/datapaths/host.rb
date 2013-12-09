# -*- coding: utf-8 -*-

module Vnet::Openflow::Datapaths

  class Host < Base

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapaths/host: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_dp_network(flows, dp_nw)
      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER,
                           priority: 30,

                           match: {
                             :eth_dst => dp_nw[:mac_address]
                           },
                           match_interface: dp_nw[:interface_id],

                           actions: {
                             :eth_dst => MAC_BROADCAST
                           },
                           write_network: dp_nw[:network_id],

                           cookie: dp_nw[:id] | COOKIE_TYPE_DP_NETWORK)
      flows << flow_create(:default,
                           table: TABLE_OUTPUT_DP_NETWORK_SRC,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 1,

                           match_value_pair_first: dp_nw[:network_id],
                           write_value_pair_first: dp_nw[:interface_id],

                           cookie: dp_nw[:id] | COOKIE_TYPE_DP_NETWORK)
    end

    def flows_for_dp_route_link(flows, dp_rl)
      # We match the route link id stored in the first value field to
      # the one associated with this host's datapath, and then prepare
      # for the next table by storing in the first value field the
      # source interface.
      #
      # We now have both source and destination interfaces on the host
      # and remote datapaths, which have either tunnel or MAC2MAC
      # associations usable for output to the proper port.

      flows << flow_create(:default,
                           table: TABLE_OUTPUT_DP_ROUTE_LINK_SRC,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 1,

                           match_value_pair_first: dp_rl[:route_link_id],
                           write_value_pair_first: dp_rl[:interface_id],

                           cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)
    end

  end

end
