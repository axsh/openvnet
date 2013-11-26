# -*- coding: utf-8 -*-

module Vnet::Openflow::Datapaths

  class Remote < Base

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapaths/remote: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_dp_route_link(flows, dp_rl)
      flows << flow_create(:default,
                           table: TABLE_OUTPUT_DP_ROUTE_LINK_LOOKUP_DST,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 5,

                           match_dp_route_link: dp_rl[:id],

                           actions: {
                             :eth_dst => dp_rl[:mac_address]
                           },

                           # write pair..

                           cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)

    end

  end

end
