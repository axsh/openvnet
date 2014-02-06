# -*- coding: utf-8 -*-

module Vnet::Openflow::Datapaths

  class Remote < Base

    def uninstall
      if same_segment?
        @dp_info.dc_segment_manager.async.remove_datapath(id)
      else
        @dp_info.tunnel_manager.async.unload(dst_id: id)
      end
    end

    private

    def same_segment?
      @dp_info.datapath.datapath_info.dc_segment_id == @dc_segment_id
    end

    def after_add_active_network(active_network)
      if same_segment?
        @dp_info.dc_segment_manager.async.insert(active_network[:dpn_id])
      else
        @dp_info.tunnel_manager.async.insert(active_network[:dpn_id])
      end

      flows = []
      flows_for_filtering_mac_address(flows,
                                      active_network[:broadcast_mac_address],
                                      active_network[:dpn_id] | COOKIE_TYPE_DP_NETWORK)
      @dp_info.add_flows(flows)
    end

    def after_remove_active_network(active_network)
      if same_segment?
        @dp_info.dc_segment_manager.async.remove(active_network[:dpn_id])
      else
        @dp_info.tunnel_manager.async.remove(active_network[:dpn_id])
      end
    end

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapaths/remote: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_dp_network(flows, dp_nw)
      [true, false].each { |reflection|

        flows << flow_create(:default,
                             table: TABLE_LOOKUP_DP_NW_TO_DP_NETWORK,
                             goto_table: TABLE_OUTPUT_DP_NETWORK_DST_IF,
                             priority: 1,

                             match_value_pair_flag: reflection,
                             match_value_pair_first: @id,
                             match_value_pair_second: dp_nw[:network_id],

                             clear_all: true,
                             write_reflection: reflection,
                             write_dp_network: dp_nw[:id],

                             cookie: dp_nw[:id] | COOKIE_TYPE_DP_NETWORK)

        flows << flow_create(:default,
                             table: TABLE_OUTPUT_DP_NETWORK_DST_IF,
                             goto_table: TABLE_OUTPUT_DP_NETWORK_SRC_IF,
                             priority: 1,

                             match_reflection: reflection,
                             match_dp_network: dp_nw[:id],

                             actions: {
                               :tunnel_id => dp_nw[:network_id] | TUNNEL_FLAG
                             },

                             write_value_pair_flag: reflection,
                             write_value_pair_first: dp_nw[:network_id],
                             write_value_pair_second: dp_nw[:interface_id],

                             cookie: dp_nw[:id] | COOKIE_TYPE_DP_NETWORK)
      }
    end

    def flows_for_dp_route_link(flows, dp_rl)
      # The source mac address of route link packets is required to
      # match a remote dp_rl mac address.
      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_ROUTE_LINK,
                           goto_table: TABLE_ROUTER_CLASSIFIER,
                           priority: 1,

                           match: {
                             :eth_src => dp_rl[:mac_address]
                           },
                           match_route_link: dp_rl[:route_link_id],

                           cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)

      [true, false].each { |reflection|

        flows << flow_create(:default,
                             table: TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK,
                             goto_table: TABLE_OUTPUT_DP_ROUTE_LINK_DST_IF,
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
                             table: TABLE_OUTPUT_DP_ROUTE_LINK_DST_IF,
                             goto_table: TABLE_OUTPUT_DP_ROUTE_LINK_SRC_IF,
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
