# -*- coding: utf-8 -*-

module Vnet::Core::Datapaths

  class Host < Base

    def host?
      true
    end

    def mode
      :host
    end

    def log_type
      'datapath/host'
    end

    #
    # Events:
    #

    def activate_network_id(network_id)
      network = @active_networks[network_id] || return

      return if network[:active] == true
      network[:active] == true

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_HOST_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def deactivate_network_id(network_id)
      network = @active_networks[network_id] || return

      return if network[:active] == false
      network[:active] == false

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_HOST_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def activate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == true
      route_link[:active] == true

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_HOST_DATAPATH_ROUTE_LINK,
                                      id: :datapath_route_link,
                                      dp_obj: route_link)
    end

    def deactivate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == false
      route_link[:active] == false

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_HOST_DATAPATH_ROUTE_LINK,
                                      id: :datapath_route_link,
                                      dp_obj: route_link)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_dp_network(flows, dp_nw)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
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
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_NW_IF,
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER,
                           priority: 1,

                           match_value_pair_flag: true,
                           match_value_pair_first: dp_nw[:network_id],
                           match_value_pair_second: dp_nw[:interface_id],

                           clear_all: true,
                           write_remote: true,
                           write_network: dp_nw[:network_id],

                           cookie: dp_nw[:id] | COOKIE_TYPE_DP_NETWORK)
      flows << flow_create(table: TABLE_LOOKUP_NETWORK_TO_HOST_IF_EGRESS,
                           goto_table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                           priority: 1,

                           match_network: dp_nw[:network_id],
                           write_interface: dp_nw[:interface_id],

                           cookie: dp_nw[:id] | COOKIE_TYPE_DP_NETWORK)
      flows << flow_create(table: TABLE_OUTPUT_DP_NETWORK_SRC_IF,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 1,

                           match_value_pair_first: dp_nw[:network_id],
                           write_value_pair_first: dp_nw[:interface_id],

                           cookie: dp_nw[:id] | COOKIE_TYPE_DP_NETWORK)
    end

    def flows_for_dp_route_link(flows, dp_rl)
      # The router manager does not know about the dp_rl's mac
      # address, so we create the flow here.
      #
      # TODO: Add verification of the ingress host interface.
      flows << flow_create(table: TABLE_TUNNEL_NETWORK_IDS,
                           goto_table: TABLE_ROUTER_CLASSIFIER,
                           priority: 30,

                           match: {
                             :tunnel_id => TUNNEL_ROUTE_LINK,
                             :eth_dst => dp_rl[:mac_address]
                           },
                           write_route_link: dp_rl[:route_link_id],

                           cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)

      # We match the route link id stored in the first value field
      # with the dp_rl associated with this datapath, and then prepare
      # for the next table by storing the source host interface in the
      # first value field.
      #
      # We now have both source and destination interfaces on the host
      # and remote datapaths, which have either tunnel or MAC2MAC
      # flows usable for output to the proper port.

      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_ROUTE_LINK,
                           priority: 30,
                           match: {
                             :eth_dst => dp_rl[:mac_address]
                           },
                           match_interface: dp_rl[:interface_id],
                           write_route_link: dp_rl[:route_link_id],

                           cookie: dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)

      # The source mac address is set to this datapath's dp_rl's mac
      # address in order to uniquely identify the packets as being
      # from this datapath.
      flows << flow_create(table: TABLE_OUTPUT_DP_ROUTE_LINK_SRC_IF,
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
