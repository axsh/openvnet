# -*- coding: utf-8 -*-

module Vnet::Core::Interfaces

  class Host < IfBase

    def log_type
      'interface/host'
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

      if @enable_routing
        flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
        flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
      end

#      flows_for_disabled_filtering(flows, ipv4_info) unless @enabled_filtering

      @dp_info.add_flows(flows)
    end

    def install
      flows = []

      flows_for_disabled_filtering(flows) unless @enabled_filtering
      flows_for_disabled_legacy_filtering(flows) unless @ingress_filtering_enabled

      flows_for_base(flows)

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
      flows << flow_create(table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 10,
                           match_interface: @id,
                           actions: {
                             :output => OFPP_LOCAL
                           })
    end

    def flows_for_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      #
      # Classifiers:
      #
      flows << flow_create(table: TABLE_LOCAL_PORT,
                           goto_table: TABLE_INTERFACE_EGRESS_CLASSIFIER,
                           priority: 30,
                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           write_interface: @id,
                           cookie: cookie)
    end

    def flows_for_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      # We currently only support a single physical network for a
      # host interface.
      #
      # Until network segments are supported this is difficult to
      # implement.
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_MAC,
                           priority: 10,
                           match_interface: @id,
                           cookie: cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_IF,
                           priority: 20,

                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           match_interface: @id,
                           write_value_pair_flag: true,
                           write_value_pair_first: ipv4_info[:network_id],

                           cookie: cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_IF,
                           priority: 20,

                           match: {
                             :eth_dst => MAC_BROADCAST
                           },
                           match_interface: @id,
                           write_value_pair_flag: true,
                           write_value_pair_first: ipv4_info[:network_id],

                           cookie: cookie)
    end

  end

end
