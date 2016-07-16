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

      debug log_format("activating network #{network_id} on #{self.pretty_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_HOST_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def deactivate_network_id(network_id)
      network = @active_networks[network_id] || return

      return if network[:active] == false
      network[:active] == false

      debug log_format("deactivating network #{network_id} on #{self.pretty_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_HOST_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def activate_segment_id(segment_id)
      segment = @active_segments[segment_id] || return

      return if segment[:active] == true
      segment[:active] == true

      debug log_format("activating segment #{segment_id} on #{self.pretty_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_HOST_DATAPATH_SEGMENT,
                                      id: :datapath_segment,
                                      dp_obj: segment)
    end

    def deactivate_segment_id(segment_id)
      segment = @active_segments[segment_id] || return

      return if segment[:active] == false
      segment[:active] == false

      debug log_format("deactivating segment #{segment_id} on #{self.pretty_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_HOST_DATAPATH_SEGMENT,
                                      id: :datapath_segment,
                                      dp_obj: segment)
    end

    def activate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == true
      route_link[:active] == true

      debug log_format("activating route link #{route_link_id} on #{self.pretty_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_HOST_DATAPATH_ROUTE_LINK,
                                      id: :datapath_route_link,
                                      dp_obj: route_link)
    end

    def deactivate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == false
      route_link[:active] == false

      debug log_format("deactivating route link #{route_link_id} on #{self.pretty_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_HOST_DATAPATH_ROUTE_LINK,
                                      id: :datapath_route_link,
                                      dp_obj: route_link)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_dp_network(flows, dp_nw)
      dp_nw_cookie = dp_nw[:id] | COOKIE_TYPE_DP_NETWORK
      network_id = dp_nw[:network_id]
      interface_id = dp_nw[:interface_id]
      mac_address = dp_nw[:mac_address]

      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_IF,
                           priority: 30,

                           match: {
                             :eth_dst => mac_address
                           },
                           match_interface: interface_id,

                           actions: {
                             :eth_dst => MAC_BROADCAST
                           },
                           write_value_pair_flag: true,
                           write_value_pair_first: network_id,

                           cookie: dp_nw_cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_NW_IF,
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER,
                           priority: 1,

                           match_value_pair_flag: true,
                           match_value_pair_first: network_id,
                           match_value_pair_second: interface_id,

                           clear_all: true,
                           write_remote: true,
                           write_network: network_id,

                           cookie: dp_nw_cookie)
      flows << flow_create(table: TABLE_LOOKUP_NETWORK_TO_HOST_IF_EGRESS,
                           goto_table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                           priority: 1,

                           match_network: network_id,
                           write_interface: interface_id,

                           cookie: dp_nw_cookie)
      flows << flow_create(table: TABLE_OUTPUT_DP_NETWORK_SRC_IF,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 1,

                           match_value_pair_first: network_id,
                           write_value_pair_first: interface_id,

                           cookie: dp_nw_cookie)
    end

    def flows_for_dp_route_link(flows, dp_rl)
      dp_rl_cookie = dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK
      interface_id = dp_rl[:interface_id]
      route_link_id = dp_rl[:route_link_id]
      mac_address = dp_rl[:mac_address]

      # The router manager does not know about the dp_rl's mac
      # address, so we create the flow here.
      #
      # TODO: Add verification of the ingress host interface.
      flows << flow_create(table: TABLE_TUNNEL_IDS,
                           goto_table: TABLE_ROUTER_CLASSIFIER,
                           priority: 30,

                           match: {
                             :tunnel_id => TUNNEL_ROUTE_LINK,
                             :eth_dst => mac_address
                           },
                           write_route_link: route_link_id,

                           cookie: dp_rl_cookie)

      # We match the route link id stored in the first value field
      # with the dpg_map associated with this datapath, and then prepare
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
                             :eth_dst => mac_address
                           },
                           match_interface: interface_id,
                           write_route_link: route_link_id,

                           cookie: dp_rl_cookie)

      # The source mac address is set to this datapath's dpg_map's mac
      # address in order to uniquely identify the packets as being
      # from this datapath.
      flows << flow_create(table: TABLE_OUTPUT_DP_ROUTE_LINK_SRC_IF,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 1,

                           match_value_pair_first: route_link_id,
                           write_value_pair_first: interface_id,

                           actions: {
                             :eth_src => mac_address
                           },

                           cookie: dp_rl_cookie)

      flows_for_filtering_mac_address(flows, mac_address, dp_rl_cookie)
    end

  end

end
