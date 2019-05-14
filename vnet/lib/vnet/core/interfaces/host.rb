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
      flows_for_interface_ipv4(flows, mac_info, ipv4_info)

      if @enable_routing
        flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
        flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
      end

      @dp_info.add_flows(flows)
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
      flows << flow_create(table: TABLE_OUT_PORT_INGRESS_IF_NIL,
                           priority: 10,

                           match_first: @id,

                           actions: {
                             :output => :local
                           })
    end

    def flows_for_mac(flows, mac_info)
      flow_cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      #
      # Classifiers:
      #
      flows << flow_create(table: TABLE_LOCAL_PORT,
                           goto_table: TABLE_INTERFACE_EGRESS_CLASSIFIER_IF_NIL,
                           priority: 30,
                           
                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           
                           write_remote: false,
                           write_first: @id,
                           write_second: 0,

                           cookie: flow_cookie)
    end

    def flows_for_ipv4(flows, mac_info, ipv4_info)
      flow_cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      # We currently only support a single physical network for a
      # host interface.
      #
      # Until network segments are supported this is difficult to
      # implement.
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                           priority: 10,

                           match_first: @id,

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                           priority: 20,

                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           match_first: @id,

                           write_second: ipv4_info[:network_id],

                           cookie: flow_cookie)
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                           priority: 21,

                           match: {
                             :eth_dst => MAC_BROADCAST
                           },

                           write_first: @id,
                           write_second: ipv4_info[:network_id],

                           cookie: flow_cookie)
    end

  end

end
