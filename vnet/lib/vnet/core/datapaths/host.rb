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
      network[:active] = true

      debug log_format("activating network #{network_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_HOST_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def deactivate_network_id(network_id)
      network = @active_networks[network_id] || return

      return if network[:active] == false
      network[:active] = false

      debug log_format("deactivating network #{network_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_HOST_DATAPATH_NETWORK,
                                      id: :datapath_network,
                                      dp_obj: network)
    end

    def activate_segment_id(segment_id)
      segment = @active_segments[segment_id] || return

      return if segment[:active] == true
      segment[:active] = true

      debug log_format("activating segment #{segment_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_HOST_DATAPATH_SEGMENT,
                                      id: :datapath_segment,
                                      dp_obj: segment)
    end

    def deactivate_segment_id(segment_id)
      segment = @active_segments[segment_id] || return

      return if segment[:active] == false
      segment[:active] = false

      debug log_format("deactivating segment #{segment_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_HOST_DATAPATH_SEGMENT,
                                      id: :datapath_segment,
                                      dp_obj: segment)
    end

    def activate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == true
      route_link[:active] = true

      debug log_format("activating route link #{route_link_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::ADDED_HOST_DATAPATH_ROUTE_LINK,
                                      id: :datapath_route_link,
                                      dp_obj: route_link)
    end

    def deactivate_route_link_id(route_link_id)
      route_link = @active_route_links[route_link_id] || return

      return if route_link[:active] == false
      route_link[:active] = false

      debug log_format("deactivating route link #{route_link_id}")

      @dp_info.tunnel_manager.publish(Vnet::Event::REMOVED_HOST_DATAPATH_ROUTE_LINK,
                                      id: :datapath_route_link,
                                      dp_obj: route_link)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_dp_network(flows, dpg_map)
      flow_cookie = dpg_map[:id] | COOKIE_TYPE_DP_NETWORK

      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_DPNW,
                           priority: 30,

                           match: {
                             :eth_dst => dpg_map[:mac_address]
                           },
                           match_interface: dpg_map[:interface_id],

                           actions: {
                             :eth_dst => MAC_BROADCAST
                           },
                           write_value_pair_flag: true,
                           write_value_pair_first: dpg_map[:network_id],
                           write_value_pair_second: dpg_map[:id],

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_NW_IF,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_DPNW,
                           priority: 1,

                           match_value_pair_first: dpg_map[:network_id],
                           match_value_pair_second: dpg_map[:interface_id],

                           write_value_pair_second: dpg_map[:id],

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_NW_DPNW,
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER,
                           priority: 1,

                           match_value_pair_first: dpg_map[:network_id],
                           match_value_pair_second: dpg_map[:id],

                           clear_all: true,
                           write_remote: true,
                           write_network: dpg_map[:network_id],

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_LOOKUP_NETWORK_TO_HOST_IF_EGRESS,
                           goto_table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                           priority: 1,

                           match_network: dpg_map[:network_id],
                           write_interface: dpg_map[:interface_id],

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_OUTPUT_DP_NETWORK_SRC_IF,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 1,

                           match_value_pair_first: dpg_map[:network_id],

                           write_value_pair_first: dpg_map[:interface_id],

                           cookie: flow_cookie)

      flows_for_filtering_mac_address(flows, dpg_map[:mac_address], flow_cookie)

      ovs_flows = []
      ovs_flows << create_learn_network_arp(dpg_map, 51, "tun_id=0,")
      ovs_flows << create_learn_network_arp(dpg_map, 50, "", "load:NXM_NX_TUN_ID[]->NXM_NX_TUN_ID[],")
      ovs_flows.each { |flow| @dp_info.add_ovs_flow(flow) }
    end

    def flows_for_dp_segment(flows, dpg_map)
      flow_cookie = dpg_map[:id] | COOKIE_TYPE_DP_SEGMENT

      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_SEG_DPSEG,
                           priority: 30,

                           match: {
                             :eth_dst => dpg_map[:mac_address]
                           },
                           match_interface: dpg_map[:interface_id],

                           actions: {
                             :eth_dst => MAC_BROADCAST
                           },
                           write_value_pair_flag: true,
                           write_value_pair_first: dpg_map[:segment_id],
                           write_value_pair_second: dpg_map[:id],

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_SEG_IF,
                           goto_table: TABLE_INTERFACE_INGRESS_SEG_DPSEG,
                           priority: 1,

                           match_value_pair_first: dpg_map[:segment_id],
                           match_value_pair_second: dpg_map[:interface_id],

                           write_value_pair_second: dpg_map[:id],

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_SEG_DPSEG,
                           goto_table: TABLE_SEGMENT_SRC_CLASSIFIER,
                           priority: 1,

                           match_value_pair_first: dpg_map[:segment_id],
                           match_value_pair_second: dpg_map[:id],

                           clear_all: true,
                           write_remote: true,
                           write_segment: dpg_map[:segment_id],

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_LOOKUP_SEGMENT_TO_HOST_IF_EGRESS,
                           goto_table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                           priority: 1,

                           match_segment: dpg_map[:segment_id],
                           write_interface: dpg_map[:interface_id],
                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_OUTPUT_DP_SEGMENT_SRC_IF,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 1,

                           match_value_pair_first: dpg_map[:segment_id],

                           write_value_pair_first: dpg_map[:interface_id],
                           cookie: flow_cookie)

      flows_for_filtering_mac_address(flows, dpg_map[:mac_address], flow_cookie)

      # Handle broadcast packets using the OF-only learning flows.
      flow_cookie = dpg_map[:segment_id] | COOKIE_TYPE_SEGMENT

      flows << flow_create(table: TABLE_CONTROLLER_PORT,
                           goto_table: TABLE_SEGMENT_DST_CLASSIFIER,
                           priority: 20,
                           match: {
                             # :eth_type => 0x0806
                             :eth_dst => dpg_map[:mac_address]
                           },
                           actions: {
                             :eth_dst => MAC_BROADCAST
                           },
                           write_segment: dpg_map[:segment_id],
                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_OUTPUT_DP_TO_CONTROLLER,
                           priority: 1,
                           match: {
                             :eth_dst => MAC_BROADCAST
                           },
                           match_segment: dpg_map[:segment_id],
                           actions: {
                             :eth_dst => dpg_map[:mac_address],
                             :output => OFPP_CONTROLLER
                           },
                           cookie: flow_cookie)

      ovs_flows = []
      ovs_flows << create_learn_segment_arp(dpg_map, 51, "tun_id=0,")
      ovs_flows << create_learn_segment_arp(dpg_map, 50, "", "load:NXM_NX_TUN_ID[]->NXM_NX_TUN_ID[],")
      ovs_flows.each { |flow| @dp_info.add_ovs_flow(flow) }
    end

    def flows_for_dp_route_link(flows, dpg_map)
      flow_cookie = dpg_map[:id] | COOKIE_TYPE_DP_ROUTE_LINK

      # The router manager does not know about the dpg_map's mac
      # address, so we create the flow here.
      #
      # TODO: Add verification of the ingress host interface.
      flows << flow_create(table: TABLE_TUNNEL_IDS,
                           goto_table: TABLE_ROUTER_CLASSIFIER,
                           priority: 30,

                           match: {
                             :tunnel_id => TUNNEL_ROUTE_LINK,
                             :eth_dst => dpg_map[:mac_address]
                           },
                           write_route_link: dpg_map[:route_link_id],

                           cookie: flow_cookie)

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
                             :eth_dst => dpg_map[:mac_address]
                           },
                           match_interface: dpg_map[:interface_id],
                           write_route_link: dpg_map[:route_link_id],

                           cookie: flow_cookie)

      # The source mac address is set to this datapath's dpg_map's mac
      # address in order to uniquely identify the packets as being
      # from this datapath.
      flows << flow_create(table: TABLE_OUTPUT_DP_ROUTE_LINK_SRC_IF,
                           goto_table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                           priority: 1,

                           match_value_pair_first: dpg_map[:route_link_id],
                           write_value_pair_first: dpg_map[:interface_id],

                           actions: {
                             :eth_src => dpg_map[:mac_address]
                           },

                           cookie: flow_cookie)

      flows_for_filtering_mac_address(flows, dpg_map[:mac_address], flow_cookie)
    end

    def create_learn_segment_arp(dpg_map, priority, match_options = "", learn_options = "")
      #
      # Work around the current limitations of trema / openflow 1.3 using ovs-ofctl directly.
      #
      match_dpg_md = md_create(match_value_pair_flag: true, match_value_pair_first: dpg_map[:segment_id], match_value_pair_second: dpg_map[:id])
      write_md = md_create(clear_all: true, write_remote: true, write_segment: dpg_map[:segment_id])

      flow_cookie = dpg_map[:id] | COOKIE_TYPE_DP_SEGMENT

      flow_learn_arp = "table=%d,priority=%d,cookie=0x%x,arp,metadata=0x%x/0x%x,%sactions=" %
        [TABLE_INTERFACE_INGRESS_SEG_DPSEG, priority, flow_cookie, match_dpg_md[:metadata], match_dpg_md[:metadata_mask], match_options]

      [md_create(match_segment: dpg_map[:segment_id], match_local: nil),
       md_create(segment: dpg_map[:segment_id], match_reflection: true)
      ].each { |metadata|
        flow_learn_arp << "learn(table=%d,cookie=0x%x,idle_timeout=36000,priority=35,metadata:0x%x,NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[]," %
          [TABLE_SEGMENT_DST_MAC_LOOKUP, flow_cookie, metadata[:metadata]]
        flow_learn_arp << learn_options
        flow_learn_arp << "output:NXM_OF_IN_PORT[]),"
      }

      flow_learn_arp << "write_metadata:0x%x/0x%x,goto_table:%d" % [write_md[:metadata], write_md[:metadata_mask], TABLE_SEGMENT_SRC_CLASSIFIER]
      flow_learn_arp
    end

    def create_learn_network_arp(dpg_map, priority, match_options = "", learn_options = "")
      #
      # Work around the current limitations of trema / openflow 1.3 using ovs-ofctl directly.
      #
      match_dpg_md = md_create(match_value_pair_flag: true, match_value_pair_first: dpg_map[:network_id], match_value_pair_second: dpg_map[:id])
      write_md = md_create(clear_all: true, write_remote: true, write_network: dpg_map[:network_id])

      flow_cookie = dpg_map[:id] | COOKIE_TYPE_DP_NETWORK

      flow_learn_arp = "table=%d,priority=%d,cookie=0x%x,arp,metadata=0x%x/0x%x,%sactions=" %
        [TABLE_INTERFACE_INGRESS_NW_DPNW, priority, flow_cookie, match_dpg_md[:metadata], match_dpg_md[:metadata_mask], match_options]

      [md_create(match_network: dpg_map[:network_id], match_local: nil),
       md_create(network: dpg_map[:network_id], match_reflection: true)
      ].each { |metadata|
        flow_learn_arp << "learn(table=%d,cookie=0x%x,idle_timeout=36000,priority=35,metadata:0x%x,NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[]," %
          [TABLE_NETWORK_DST_MAC_LOOKUP, flow_cookie, metadata[:metadata]]
        flow_learn_arp << learn_options
        flow_learn_arp << "output:NXM_OF_IN_PORT[]),"
      }

      flow_learn_arp << "write_metadata:0x%x/0x%x,goto_table:%d" % [write_md[:metadata], write_md[:metadata_mask], TABLE_NETWORK_SRC_CLASSIFIER]
      flow_learn_arp
    end

  end

end
