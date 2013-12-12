# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  # Base class for regular interfaces.

  class IfBase < Base
    
    #
    # Router ingress/egress:
    #

    def enable_router_ingress
      return if @router_ingress != false
      @router_ingress = true

      flows = []

      @mac_addresses.each { |mac_lease_id, mac_info|
        flows_for_router_ingress_mac(flows, mac_info)

        mac_info[:ipv4_addresses].each { |ipv4_info|
          flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
          flows_for_router_ingress_mac2mac_ipv4(flows, mac_info, ipv4_info)
        }
      }

      @dp_info.add_flows(flows)
    end

    def disable_router_ingress
      # Not supported atm.
    end

    def enable_router_egress
      return if @router_egress != false
      @router_egress = true

      flows = []

      @mac_addresses.each { |mac_lease_id, mac_info|
        flows_for_router_egress_mac(flows, mac_info)

        mac_info[:ipv4_addresses].each { |ipv4_info|
          flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
        }
      }

      @dp_info.add_flows(flows)
    end

    def disable_router_egress
      # Not supported atm.
    end

    #
    # Internal methods:
    #

    private

    def flows_for_interface_mac(flows, mac_info)
    end

    def flows_for_interface_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      #
      # Classifier
      #
      flows << flow_create(:interface_classifier,
                           priority: 40,
                           match: {
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                             :ipv4_src => IPV4_ZERO
                           },
                           interface_id: @id,
                           write_network_id: ipv4_info[:network_id],
                           cookie: cookie)
      flows << flow_create(:interface_classifier,
                           priority: 40,
                           match: {
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                             :ipv4_src => ipv4_info[:ipv4_address]
                           },
                           interface_id: @id,
                           write_network_id: ipv4_info[:network_id],
                           cookie: cookie)
      flows << flow_create(:interface_classifier,
                           priority: 40,
                           match: {
                             :eth_type => 0x0806,
                             :eth_src => mac_info[:mac_address],
                             :arp_sha => mac_info[:mac_address],
                             :arp_spa => ipv4_info[:ipv4_address]
                           },
                           interface_id: @id,
                           write_network_id: ipv4_info[:network_id],
                           cookie: cookie)

      #
      # ARP anti-spoof
      #
      flows << flow_create(:default,
                           table_network_src: ipv4_info[:network_type],
                           priority: 85,
                           match: {
                             :eth_type => 0x0806,
                             :arp_spa => ipv4_info[:ipv4_address],
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie)
      flows << flow_create(:default,
                           table_network_src: ipv4_info[:network_type],
                           priority: 85,
                           match: {
                             :eth_type => 0x0806,
                             :eth_src => mac_info[:mac_address],
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie)
      flows << flow_create(:default,
                           table_network_src: ipv4_info[:network_type],
                           priority: 85,
                           match: {
                             :eth_type => 0x0806,
                             :arp_sha => mac_info[:mac_address],
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie)

      #
      # IPv4 
      #
      flows << flow_create(:default,
                           table_network_src: ipv4_info[:network_type],
                           priority: 44,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_src => ipv4_info[:ipv4_address],
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie)
      flows << flow_create(:default,
                           table_network_src: ipv4_info[:network_type],
                           priority: 44,
                           match: {
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie)
      flows << flow_create(:default,
                           table_network_src: ipv4_info[:network_type],
                           priority: 34,
                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie)
      flows << flow_create(:router_dst_match,
                           priority: 40,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_dst => ipv4_info[:ipv4_address],
                           },
                           actions: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           cookie: cookie)
    end

    def flows_for_router_ingress_mac(flows, mac_info)
    end

    def flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(:router_classifier,
                           match: {
                             :eth_type => 0x0800,
                             :eth_dst => mac_info[:mac_address]
                           },
                           network_id: ipv4_info[:network_id],
                           ingress_interface_id: @id,
                           cookie: cookie)
      flows << flow_create(:router_classifier,
                           match: {
                             :eth_type => 0x0800,
                             :eth_dst => mac_info[:mac_address],
                             :ipv4_dst => ipv4_info[:ipv4_address]
                           },
                           network_id: ipv4_info[:network_id],
                           ingress_interface_id: nil,
                           cookie: cookie)
    end

    def flows_for_router_ingress_mac2mac_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_MAC,
                           priority: 20,

                           match: {
                             :eth_type => 0x0800,
                             :eth_dst => mac_info[:mac_address]
                           },

                           write_value_pair_flag: true,
                           write_value_pair_first: ipv4_info[:network_id],
                           # write_value_pair_second: <- host interface id, already set.

                           cookie: cookie,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_IF)
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
    end

    def flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      #
      # Not needed unless egress routing is used:
      #

      # TODO: Currently only one mac address / network is supported.
      flows << flow_create(:default,
                           table: TABLE_INTERFACE_EGRESS_MAC,
                           priority: 20,
                           match: {
                             :eth_src => mac_info[:mac_address]
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie,
                           goto_table: TABLE_ARP_TABLE)
      flows << flow_create(:default,
                           table: TABLE_ROUTE_EGRESS_INTERFACE,
                           priority: 20,
                           actions: {
                             :eth_src => mac_info[:mac_address]
                           },
                           match_interface: @id,
                           write_network: ipv4_info[:network_id],
                           cookie: cookie,
                           goto_table: TABLE_ARP_TABLE)
    end    

    def flows_for_mac2mac_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      [{ :eth_type => 0x0800,
         :eth_dst => mac_info[:mac_address],
         :ipv4_dst => ipv4_info[:ipv4_address]
       }, {
         :eth_type => 0x0806,
         :eth_dst => mac_info[:mac_address],
         :arp_tpa => ipv4_info[:ipv4_address]
       }].each { |match|
        flows << flow_create(:default,
                             table: TABLE_INTERFACE_INGRESS_MAC,
                             priority: 30,

                             match: match,
                             write_value_pair_flag: true,
                             write_value_pair_first: ipv4_info[:network_id],
                             # write_value_pair_second: <- host interface id, already set.

                             cookie: cookie,
                             goto_table: TABLE_INTERFACE_INGRESS_NW_IF)
      }
    end

  end

end
