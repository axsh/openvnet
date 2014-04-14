# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Patch < IfBase

    def add_mac_address(params)
      mac_info = super

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
      mac_info, ipv4_info = super

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
      flows_for_disabled_filtering(flows) unless @ingress_filtering_enabled
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

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} interfaces/patch: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_base(flows)
    end

    def flows_for_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      #
      # Classifiers:
      #
      # flows << flow_create(:default,
      #                      table: TABLE_LOCAL_PORT,
      #                      goto_table: TABLE_INTERFACE_EGRESS_CLASSIFIER,
      #                      priority: 30,
      #                      match: {
      #                        :eth_src => mac_info[:mac_address],
      #                      },
      #                      write_interface: @id,
      #                      cookie: cookie)
    end

    def flows_for_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_MAC,
                           priority: 10,
                           match_interface: @id,
                           cookie: cookie)

      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_IF,
                           priority: 20,

                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           match_interface: @id,
                           write_value_pair_flag: true,
                           write_value_pair_first: ipv4_info[:network_id],

                           cookie: cookie)
      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_IF,
                           priority: 20,

                           match: {
                             :eth_dst => MAC_BROADCAST
                           },
                           match_interface: @id,
                           write_value_pair_flag: true,
                           write_value_pair_first: ipv4_info[:network_id],

                           cookie: cookie)

      # flows << flow_create(:default,
      #                      table: TABLE_OUT_PORT_INTERFACE_INGRESS,
      #                      priority: 10,
      #                      match_interface: @id,
      #                      actions: {
      #                        :output => OFPP_LOCAL
      #                      })
    end

    def flows_for_router_egress_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      flows << flow_create(:default,
                           table: TABLE_INTERFACE_EGRESS_CLASSIFIER,
                           priority: 20,
                           match: {
                             :eth_src => mac_info[:mac_address]
                           },
                           match_interface: @id,
                           cookie: cookie,
                           goto_table: TABLE_INTERFACE_EGRESS_ROUTES)

      # FOOO
      flows << flow_create(:default,
                           table: TABLE_ROUTE_EGRESS_INTERFACE,
                           goto_table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                           priority: 20,

                           actions: {
                             :eth_src => Trema::Mac.new('00:00:27:11:11:11'),
                             :eth_dst => Trema::Mac.new('00:00:27:22:22:22'),
                           },
                           match_interface: @id,

                           cookie: cookie)
    end

    def flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      #
      # Not needed unless egress routing is used:
      #

      # TODO: Currently only one mac address / network is supported.
      flows << flow_create(:default,
                           table: TABLE_INTERFACE_EGRESS_MAC,
                           goto_table: TABLE_ARP_TABLE,
                           priority: 20,
                           match: {
                             :eth_src => mac_info[:mac_address]
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie)
      flows << flow_create(:default,
                           table: TABLE_ROUTE_EGRESS_LOOKUP,
                           goto_table: TABLE_ROUTE_EGRESS_TRANSLATION,
                           priority: 1,

                           match_value_pair_first: @id,

                           clear_all: true,
                           write_reflection: true,
                           write_interface: @id,

                           cookie: cookie)
    end

  end

end
