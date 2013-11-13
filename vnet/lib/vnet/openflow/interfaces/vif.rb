# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Vif < IfBase

    def add_mac_address(params)
      mac_info = super

      flows = []
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
                                                mode: :vif,
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
                                                mode: :vif,
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
      "#{@dp_info.dpid_s} interfaces/vif: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_base(flows)
    end

    def flows_for_mac(flows, mac_info)
      # flows << flow_create(:segment_src,
      #                      priority: 85,
      #                      match: {
      #                        :eth_type => 0x0806,
      #                        :eth_src => mac_info[:mac_address],
      #                      },
      #                      network_id: ipv4_info[:network_id],
      #                      network_type: ipv4_info[:network_type],
      #                      cookie: self.cookie)
      # flows << flow_create(:segment_src,
      #                      priority: 85,
      #                      match: {
      #                        :eth_type => 0x0806,
      #                        :arp_sha => mac_info[:mac_address],
      #                      },
      #                      network_id: ipv4_info[:network_id],
      #                      network_type: ipv4_info[:network_type],
      #                      cookie: self.cookie)
    end

    def flows_for_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(:default,
                           table: TABLE_HOST_PORTS,
                           priority: 30,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           write_network: ipv4_info[:network_id],
                           cookie: cookie,
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER)
      flows << flow_create(:default,
                           table_network_dst: ipv4_info[:network_type],
                           priority: 60,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           match_network: ipv4_info[:network_id],
                           write_interface: @id,
                           cookie: cookie,
                           goto_table: TABLE_INTERFACE_VIF)

    end

  end

end
