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
      network[:active] = true

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_REMOTE_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def deactivate_network_id(network_id)
      network = @active_networks[network_id] || return

      return if network[:active] == false
      network[:active] = false

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_REMOTE_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def activate_segment_id(segment_id)
      segment = @active_segments[segment_id] || return

      return if segment[:active] == true
      segment[:active] = true

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_REMOTE_DATAPATH_SEGMENT,
                                      id: :datapath_segment,
                                      dp_obj: segment)
    end

    def deactivate_segment_id(segment_id)
      segment = @active_segments[segment_id] || return

      return if segment[:active] == false
      segment[:active] = false

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_REMOTE_DATAPATH_SEGMENT,
                                      id: :datapath_segment,
                                      dp_obj: segment)
    end

    def activate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == true
      route_link[:active] = true

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_REMOTE_DATAPATH_ROUTE_LINK,
                                      id: :datapath_route_link,
                                      dp_obj: route_link)
    end

    def deactivate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == false
      route_link[:active] = false

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

        flows << flow_create(table: TABLE_LOOKUP_DP_NW,
                             goto_table: TABLE_OUTPUT_HOSTIF_DST_DPN_NIL,
                             priority: 1,

                             #match_remote: FLAG_REFLECTION,
                             match_first: @id,
                             match_second: flow_gen_id,

                             write_first: flow_id,
                             write_second: 0,

                             cookie: flow_cookie)

        flows << flow_create(table: TABLE_OUTPUT_HOSTIF_DST_DPN_NIL,
                             goto_table: TABLE_OUTPUT_HOSTIF_SRC_NW_DIF,
                             priority: 1,

                             #match_remote: FLAG_REFLECTION,
                             match_first: flow_id,

                             #write_remote: FLAG_REFLECTION,
                             write_first: flow_gen_id,
                             write_second: dpg_map[:interface_id],

                             actions: {
                               :tunnel_id => (flow_gen_id & TUNNEL_ID_MASK) | TUNNEL_NETWORK
                             },
                             cookie: flow_cookie)
      }
    end

    def flows_for_dp_segment(flows, dpg_map)
      flow_id = dpg_map[:id]
      flow_gen_id = dpg_map[:segment_id]
      flow_cookie = flow_id | COOKIE_TYPE_DP_SEGMENT

      [true, false].each { |reflection|

        flows << flow_create(table: TABLE_LOOKUP_DP_SEG,
                             goto_table: TABLE_OUTPUT_HOSTIF_DST_DPS_NIL,
                             priority: 1,

                             #match_remote: FLAG_REFLECTION,
                             match_first: @id,
                             match_second: flow_gen_id,

                             #write_remote: FLAG_REFLECTION,
                             write_first: flow_id,
                             write_second: 0,

                             cookie: flow_cookie)

        flows << flow_create(table: TABLE_OUTPUT_HOSTIF_DST_DPS_NIL,
                             goto_table: TABLE_OUTPUT_HOSTIF_SRC_SEG_DIF,
                             priority: 1,

                             #match_remote: FLAG_REFLECTION,
                             match_first: flow_id,

                             #match_remote: FLAG_REFLECTION,
                             write_first: flow_gen_id,
                             write_second: dpg_map[:interface_id],

                             actions: {
                               :tunnel_id => (flow_gen_id & TUNNEL_ID_MASK) | TUNNEL_SEGMENT
                             },
                             cookie: flow_cookie)
      }
    end

    def flows_for_dp_route_link(flows, dpg_map)
      flow_id = dpg_map[:id]
      flow_gen_id = dpg_map[:route_link_id]
      flow_cookie = flow_id | COOKIE_TYPE_DP_ROUTE_LINK

      # The source mac address of route link packets is required to
      # match a remote dpg_map mac address.
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_RL_DPRL,
                           goto_table: TABLE_ROUTER_CLASSIFIER_RL_NIL,
                           priority: 1,

                           match: {
                             :eth_src => dpg_map[:mac_address]
                           },
                           match_remote: FLAG_REMOTE,
                           match_first: flow_gen_id,
                           match_second: flow_id,

                           write_second: 0,

                           cookie: flow_cookie)

      [true, false].each { |reflection|
        flows << flow_create(table: TABLE_LOOKUP_DP_RL,
                             goto_table: TABLE_OUTPUT_HOSTIF_DST_DPR_NIL,
                             priority: 1,

                             #match_remote: FLAG_REFLECTION,
                             match_first: @id,
                             match_second: flow_gen_id,

                             #write_remote: FLAG_REFLECTION,
                             write_first: flow_id,
                             write_second: 0,

                             cookie: flow_cookie)

        # We write the destination interface id in the second value
        # field, and then prepare for the next table by writing the
        # route link id in the first value field.
        #
        # The route link id will then be used to identify what source
        # interface id is set using the host's datapath route link
        # entry.
        flows << flow_create(table: TABLE_OUTPUT_HOSTIF_DST_DPR_NIL,
                             goto_table: TABLE_OUTPUT_HOSTIF_SRC_RL_DIF,
                             priority: 1,

                             #match_remote: FLAG_REFLECTION,
                             match_first: flow_id,

                             #match_remote: FLAG_REFLECTION,
                             write_first: flow_gen_id,
                             write_second: dpg_map[:interface_id],

                             actions: {
                               :eth_dst => dpg_map[:mac_address],
                               :tunnel_id => TUNNEL_ROUTE_LINK
                             },
                             cookie: flow_cookie)
      }
    end

  end

end
