# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Host < IfBase

    def add_mac_address(params)
      mac_info = super

      flows = []
      flows_for_mac(flows, mac_info)
      flows_for_interface_mac(flows, mac_info)
      flows_for_router_ingress_mac(flows, mac_info) if @router_ingress == true
      flows_for_router_egress_mac(flows, mac_info) if @router_egress == true

      @dp_info.add_flows(flows)
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      @dp_info.network_manager.update_interface(event: :insert,
                                                 id: ipv4_info[:network_id],
                                                 interface_id: @id,
                                                 mode: :host,
                                                 port_number: @port_number)

      flows = []
      flows_for_ipv4(flows, mac_info, ipv4_info)
      flows_for_interface_ipv4(flows, mac_info, ipv4_info)
      flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info) if @router_ingress == true
      flows_for_router_egress_ipv4(flows, mac_info, ipv4_info) if @router_egress == true

      @dp_info.add_flows(flows)
    end

    def remove_ipv4_address(params)
      debug "interfaces: removing ipv4 flows..."

      mac_info, ipv4_info = super

      return unless ipv4_info

      @dp_info.network_manager.update_interface(event: :remove,
                                                id: ipv4_info[:network_id],
                                                interface_id: @id,
                                                mode: :host,
                                                port_number: @port_number)
    end

    def install
      flows = []
      flows_for_base(flows)

      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} interfaces/host: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_base(flows)
    end

    def flows_for_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      #
      # Classifiers:
      #
      flows << flow_create(:default,
                           table: TABLE_LOCAL_PORT,
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

      if ipv4_info[:network_type] == :physical
        # We currently only support a single physical network for a
        # host interface.
        #
        # Until network segments are supported this is difficult to
        # implement.
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
      end

      flows << flow_create(:default,
                           table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 10,
                           match_interface: @id,
                           actions: {
                             :output => OFPP_LOCAL
                           })
    end

  end

end
