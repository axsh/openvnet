# -*- coding: utf-8 -*-

module Vnet::Openflow::Datapaths

  class Host < Base

    def initialize(params)
      params[:dp_info].datapath.initialize_datapath_info(params[:map])
      super
    end

    def host?
      true
    end

    def uninstall
      super
      @dp_info.interface_manager.update_item(event: :remove_all_active_datapath)
      @dp_info.datapath.reset
    end

    private

    def after_add_active_network(active_network)
      @dp_info.dc_segment_manager.async.prepare_network(active_network[:id])
      @dp_info.tunnel_manager.async.prepare_network(active_network[:id])

      flows = []
      flows_for_filtering_mac_address(flows,
                                      active_network[:broadcast_mac_address],
                                      active_network[:dpn_id] | COOKIE_TYPE_DP_NETWORK)
      @dp_info.add_flows(flows)
    end

    def after_remove_active_network(active_network)
      @dp_info.dc_segment_manager.async.remove_network_id(active_network[:network_id])
      @dp_info.tunnel_manager.async.remove_network(active_network[:network_id])
    end

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapaths/host: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_dp_network(flows, dp_nw)
      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_IF,
                           priority: 30,

                           match: {
                             :eth_dst => dp_nw[:mac_address]
                           },
                           match_interface: dp_nw[:interface_id],

                           actions: {
                             :eth_dst => MAC_BROADCAST
                           },
                           write_value_pair_flag: true,
                           write_value_pair_first: dp_nw[:network_id],

                           cookie: dp_nw[:id] | COOKIE_TYPE_DP_NETWORK)
      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_NW_IF,
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER,
                           priority: 1,

                           match_value_pair_flag: true,
                           match_value_pair_first: dp_nw[:network_id],
                           match_value_pair_second: dp_nw[:interface_id],

                           clear_all: true,
                           write_remote: true,
                           write_network: dp_nw[:network_id],

                           cookie: dp_nw[:id] | COOKIE_TYPE_DP_NETWORK)
      flows << flow_create(:default,
                           table: TABLE_LOOKUP_NETWORK_TO_HOST_IF_EGRESS,
                           goto_table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                           priority: 1,

                           match_network: dp_nw[:network_id],
                           write_interface: dp_nw[:interface_id],

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
      # We match the route link id stored in the first value field
      # with the dp_rl associated with this datapath, and then prepare
      # for the next table by storing the source host interface in the
      # first value field.
      #
      # We now have both source and destination interfaces on the host
      # and remote datapaths, which have either tunnel or MAC2MAC
      # flows usable for output to the proper port.

      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_ROUTER_CLASSIFIER,
                           priority: 30,
                           match: {
                             :eth_dst => dp_rl[:mac_address]
                           },
                           match_interface: dp_rl[:interface_id],
                           write_route_link: @id,

                           cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)

      # The source mac address is set to this datapath's dp_rl's mac
      # address in order to uniquely identify the packets as being
      # from this datapath.
      flows << flow_create(:default,
                           table: TABLE_OUTPUT_DP_ROUTE_LINK_SRC,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 1,

                           match_value_pair_first: dp_rl[:route_link_id],
                           write_value_pair_first: dp_rl[:interface_id],

                           actions: {
                             :eth_src => dp_rl[:mac_address]
                           },

                           cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)

      flows_for_filtering_mac_address(flows,
                                      dp_rl[:mac_address],
                                      dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)
    end

  end

end
