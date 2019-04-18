# -*- coding: utf-8 -*-

module Vnet::Core::Interfaces

  class Patch < IfBase

    def log_type
      'interface/patch'
    end

    def add_mac_address(params)
      mac_info = super || return

      flows = []
      flows_for_mac(flows, mac_info)
      flows_for_interface_mac(flows, mac_info)

      if @enable_routing
        flows_for_router_ingress_mac(flows, mac_info)
        flows_for_router_egress_mac(flows, mac_info)
      end

      @dp_info.add_flows(flows)
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super || return

      flows = []
      flows_for_ipv4(flows, mac_info, ipv4_info)
      flows_for_interface_ipv4(flows, mac_info, ipv4_info)

      if @enable_routing
        flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
        flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
      end

      @dp_info.add_flows(flows)
      @dp_info.tunnel_manager.async.update(event: :updated_interface,
                                           interface_event: :added_ipv4_address,
                                           interface_mode: :patch,
                                           interface_id: @id,
                                           network_id: ipv4_info[:network_id],
                                           ipv4_address: ipv4_info[:ipv4_address])
    end

    def install
      flows = []
      flows_for_disabled_filtering(flows) unless @enabled_filtering
      flows_for_base(flows)
      flows_for_classifiers(flows)

      if @enable_routing && !@enable_route_translation
        flows_for_route_translation(flows)
      end

      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_base(flows)
    end

    def flows_for_mac(flows, mac_info)
    end

    def flows_for_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                           priority: 10,

                           match_remote: true,
                           match_first: @id,

                           cookie: cookie)

      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                           priority: 20,

                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           match_remote: true,
                           match_first: @id,

                           write_remote: true,
                           write_first: @id,
                           write_second: ipv4_info[:network_id],

                           cookie: cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                           priority: 20,

                           match: {
                             :eth_dst => MAC_BROADCAST
                           },
                           match_remote: true,
                           match_first: @id,

                           write_remote: true,
                           write_first: @id,
                           write_second: ipv4_info[:network_id],

                           cookie: cookie)
    end

    def flows_for_router_egress_mac(flows, mac_info)
      flow_cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      flows << flow_create(table: TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL,
                           goto_table: TABLE_INTERFACE_EGRESS_ROUTES_IF_NIL,
                           priority: 20,

                           match: {
                             :eth_src => mac_info[:mac_address]
                           },
                           match_first: @id,

                           cookie: flow_cookie)

      # FOOO
      flows << flow_create(table: TABLE_ROUTE_EGRESS_INTERFACE_IF_NIL,
                           goto_table: TABLE_OUT_PORT_EGRESS_IF_NIL,
                           priority: 20,

                           match_first: @id,

                           actions: {
                             :eth_src => Pio::Mac.new('00:00:27:11:11:11'),
                             :eth_dst => Pio::Mac.new('00:00:27:22:22:22'),
                           },

                           cookie: flow_cookie)
    end

    def flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
      flow_cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      #
      # Not needed unless egress routing is used:
      #

      # TODO: Currently only one mac address / network is supported.
      flows << flow_create(table: TABLE_INTERFACE_EGRESS_ROUTES_IF_NW,
                           goto_table: TABLE_ARP_TABLE_NW_NIL,
                           priority: 20,

                           match: {
                             :eth_src => mac_info[:mac_address]
                           },
                           match_first: @id,
                           match_second: ipv4_info[:network_id],

                           # write_value_pair_flag: FLAG_,
                           write_first: ipv4_info[:network_id],,
                           write_second: 0,

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_ROUTE_EGRESS_LOOKUP_IF_RL,
                           goto_table: TABLE_ROUTE_EGRESS_TRANSLATION_IF_NIL,
                           priority: 1,

                           match_first: @id,

                           write_reflection: true,
                           write_second: nil,

                           cookie: flow_cookie)
    end

  end

end
