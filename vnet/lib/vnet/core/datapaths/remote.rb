# -*- coding: utf-8 -*-

module Vnet::Core::Datapaths

  class Remote < Base

    def mode
      :remote
    end

    #
    # Events:
    #

    def log_type
      'datapath/remote'
    end

    def uninstall
      @dp_info.tunnel_manager.async.unload(dst_datapath_id: id)
    end

    def activate_network_id(network_id)
      network = @active_networks[network_id] || return

      return if network[:active] == true
      network[:active] == true

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_REMOTE_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def deactivate_network_id(network_id)
      network = @active_networks[network_id] || return

      return if network[:active] == false
      network[:active] == false

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_REMOTE_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def activate_segment_id(segment_id)
      segment = @active_segments[segment_id] || return

      return if segment[:active] == true
      segment[:active] == true

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_REMOTE_DATAPATH_SEGMENT,
                                      id: :datapath_segment,
                                      dp_obj: segment)
    end

    def deactivate_network_id(network_id)
      network = @active_networks[network_id] || return

      return if network[:active] == false
      network[:active] == false

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_REMOTE_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def activate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == true
      route_link[:active] == true

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_REMOTE_DATAPATH_ROUTE_LINK,
                                      id: :datapath_route_link,
                                      dp_obj: route_link)
    end

    def deactivate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == false
      route_link[:active] == false

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_REMOTE_DATAPATH_ROUTE_LINK,
                                      id: :datapath_route_link,
                                      dp_obj: route_link)
    end

    #
    # Internal methods:
    #

    private

    # TODO: Rewrite to use 'network' tunnel id, and identify based on
    # mac address.

    def flows_for_dp_network(flows, dpg_map)
      flow_id = dpg_map[:id]
      flow_gen_id = dpg_map[:network_id]
      flow_cookie = flow_id | COOKIE_TYPE_DP_NETWORK

      [true, false].each { |reflection|

        flows << flow_create(table: TABLE_LOOKUP_DP_NW_TO_DP_NETWORK,
                             goto_table: TABLE_OUTPUT_DP_NETWORK_DST_IF,
                             priority: 1,

                             match_value_pair_flag: reflection,
                             match_value_pair_first: @id,
                             match_value_pair_second: flow_gen_id,

                             clear_all: true,
                             write_reflection: reflection,
                             write_dp_network: flow_id,

                             cookie: flow_cookie)

        flows << flow_create(table: TABLE_OUTPUT_DP_NETWORK_DST_IF,
                             goto_table: TABLE_OUTPUT_DP_NETWORK_SRC_IF,
                             priority: 1,

                             match_reflection: reflection,
                             match_dp_network: flow_id,

                             actions: {
                               :tunnel_id => flow_gen_id | TUNNEL_FLAG
                             },

                             write_value_pair_flag: reflection,
                             write_value_pair_first: flow_gen_id,
                             write_value_pair_second: dpg_map[:interface_id],

                             cookie: flow_cookie)
      }
    end

    def flows_for_dp_segment(flows, dpg_map)
    end

    def flows_for_dp_route_link(flows, dpg_map)
      flow_id = dpg_map[:id]
      flow_gen_id = dpg_map[:route_link_id]
      flow_cookie = flow_id | COOKIE_TYPE_DP_ROUTE_LINK

      # The source mac address of route link packets is required to
      # match a remote dpg_map mac address.
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_ROUTE_LINK,
                           goto_table: TABLE_ROUTER_CLASSIFIER,
                           priority: 1,

                           match: {
                             :eth_src => dpg_map[:mac_address]
                           },
                           match_route_link: flow_gen_id,

                           cookie: flow_cookie)

      [true, false].each { |reflection|
        flows << flow_create(table: TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK,
                             goto_table: TABLE_OUTPUT_DP_ROUTE_LINK_DST_IF,
                             priority: 1,

                             match_value_pair_flag: reflection,
                             match_value_pair_first: @id,
                             match_value_pair_second: flow_gen_id,

                             clear_all: true,
                             write_reflection: reflection,
                             write_dp_route_link: flow_id,

                             cookie: flow_cookie)

        # We write the destination interface id in the second value
        # field, and then prepare for the next table by writing the
        # route link id in the first value field.
        #
        # The route link id will then be used to identify what source
        # interface id is set using the host's datapath route link
        # entry.
        flows << flow_create(table: TABLE_OUTPUT_DP_ROUTE_LINK_DST_IF,
                             goto_table: TABLE_OUTPUT_DP_ROUTE_LINK_SRC_IF,
                             priority: 1,

                             match_reflection: reflection,
                             match_dp_route_link: flow_id,

                             actions: {
                               :eth_dst => dpg_map[:mac_address],
                               :tunnel_id => TUNNEL_ROUTE_LINK
                             },

                             write_value_pair_flag: reflection,
                             write_value_pair_first: flow_gen_id,
                             write_value_pair_second: dpg_map[:interface_id],

                             cookie: flow_cookie)
      }
    end

  end

end
