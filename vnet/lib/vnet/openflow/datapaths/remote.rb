# -*- coding: utf-8 -*-

module Vnet::Openflow::Datapaths

  class Remote < Base

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapaths/remote: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_dp_route_link(flows, dp_rl)
      [true, false].each { |reflection|

        flows << flow_create(:default,
                             table: TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK,
                             goto_table: TABLE_OUTPUT_DP_ROUTE_LINK_DST,
                             priority: 1,

                             match_value_pair_flag: reflection,
                             match_value_pair_first: @id,
                             match_value_pair_second: dp_rl[:route_link_id],

                             clear_all: true,
                             write_reflection: reflection,
                             write_dp_route_link: dp_rl[:id],

                             cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)
        flows << flow_create(:default,
                             table: TABLE_OUTPUT_DP_ROUTE_LINK_SET_MAC,
                             goto_table: TABLE_OUTPUT_DP_OVER_TUNNEL,
                             priority: 1,

                             match: {
                               :eth_dst => dp_rl[:mac_address]
                             },
                             actions: {
                               :eth_dst => dp_rl[:route_link_mac_address]
                             },
                             cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)

        # We write the destination interface id in the second value
        # field, and then prepare for the next table by writing the
        # route link id in the first value field.
        #
        # The route link id will then be used to identify what source
        # interface id is set using the host's datapath route link
        # entry.
        flows << flow_create(:default,
                             table: TABLE_OUTPUT_DP_ROUTE_LINK_DST,
                             goto_table: TABLE_OUTPUT_DP_ROUTE_LINK_SRC,
                             priority: 1,

                             match_reflection: reflection,
                             match_dp_route_link: dp_rl[:id],

                             actions: {
                               :eth_dst => dp_rl[:mac_address],
                               :tunnel_id => TUNNEL_ROUTE_LINK
                             },

                             write_value_pair_flag: reflection,
                             write_value_pair_first: dp_rl[:route_link_id],
                             write_value_pair_second: dp_rl[:interface_id],

                             cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)
      }
    end

  end

end
