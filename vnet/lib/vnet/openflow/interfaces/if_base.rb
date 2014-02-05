# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  # Base class for regular interfaces.

  class IfBase < Base
    
    #
    # Internal methods:
    #

    private

    def flows_for_interface_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      #
      # Anti-spoof:
      #
      [{ :eth_src => mac_info[:mac_address],
       },{
         :eth_type => 0x0806,
         :arp_sha => mac_info[:mac_address],
       }
      ].each { |match|
        # Currently add to ingress_nw_if table since we do not
        # yet support segments.
        flows << flow_create(:default,
                             table: TABLE_INTERFACE_INGRESS_MAC,
                             priority: 50,
                             match: match,
                             #match_segment: mac_info[:segment_id],
                             cookie: cookie)
      }
    end

    def flows_for_interface_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      #
      # Classifier
      #
      [{ :eth_type => 0x0800,
         :eth_src => mac_info[:mac_address],
         :ipv4_src => IPV4_ZERO
       }, {
         :eth_type => 0x0800,
         :eth_src => mac_info[:mac_address],
         :ipv4_src => ipv4_info[:ipv4_address]
       }, {
         :eth_type => 0x0806,
         :eth_src => mac_info[:mac_address],
         :arp_sha => mac_info[:mac_address],
         :arp_spa => ipv4_info[:ipv4_address]
       }].each { |match|
        flows << flow_create(:default,
                             table: TABLE_INTERFACE_EGRESS_CLASSIFIER,
                             goto_table: TABLE_INTERFACE_EGRESS_FILTER,
                             priority: 30,
                             match: match,
                             match_interface: @id,
                             write_network: ipv4_info[:network_id],
                             cookie: cookie)
      }

      #
      # IPv4 
      #
      flows << flow_create(:default,
                           table: TABLE_ARP_TABLE,
                           goto_table: TABLE_NETWORK_DST_CLASSIFIER,
                           priority: 40,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_dst => ipv4_info[:ipv4_address],
                           },
                           match_network: ipv4_info[:network_id],
                           actions: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           cookie: cookie)
      flows << flow_create(:default,
                           table: TABLE_NETWORK_DST_MAC_LOOKUP,
                           goto_table: TABLE_INTERFACE_INGRESS_FILTER,
                           priority: 60,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           match_network: ipv4_info[:network_id],
                           write_interface: @id,
                           cookie: cookie)

      #
      # Anti-spoof:
      #
      [{ :eth_type => 0x0806,
         :arp_spa => ipv4_info[:ipv4_address],
       },{
         :eth_type => 0x0800,
         :ipv4_src => ipv4_info[:ipv4_address],
       }
      ].each { |match|
        flows << flow_create(:default,
                             table: TABLE_INTERFACE_INGRESS_NW_IF,
                             priority: 90,
                             match: match,
                             match_value_pair_first: ipv4_info[:network_id],
                             cookie: cookie)
      }
    end

    def flows_for_router_ingress_mac(flows, mac_info)
    end

    def flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(:default,
                           table: TABLE_ROUTE_INGRESS_INTERFACE,
                           goto_table: TABLE_NETWORK_DST_CLASSIFIER,
                           priority: 20,
                           match: {
                             :eth_type => 0x0800,
                             :eth_dst => mac_info[:mac_address],
                             :ipv4_dst => ipv4_info[:ipv4_address]
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie)

      flows << flow_create(:default,
                           table: TABLE_ROUTE_INGRESS_INTERFACE,
                           goto_table: TABLE_ROUTE_INGRESS_TRANSLATION,
                           priority: 10,
                           match: {
                             :eth_type => 0x0800,
                             :eth_dst => mac_info[:mac_address]
                           },
                           match_network: ipv4_info[:network_id],
                           write_interface: @id,
                           cookie: cookie)
    end

    # TODO: Rename:
    def flows_for_router_ingress_mac2mac_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_MAC,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_IF,
                           priority: 20,

                           match: {
                             :eth_dst => mac_info[:mac_address]
                           },

                           write_value_pair_flag: true,
                           write_value_pair_first: ipv4_info[:network_id],

                           cookie: cookie)

      # Handle packets from simulated interfaces that can be on
      # multiple datapaths.
      #
      # Should be improved to use unique mac addresses in the case of
      # mac2mac.
      flows << flow_create(:default,
                           table: TABLE_INTERFACE_INGRESS_MAC,
                           goto_table: TABLE_INTERFACE_INGRESS_NW_IF,
                           priority: 60,

                           match: {
                             :eth_src => mac_info[:mac_address]
                           },

                           write_value_pair_flag: true,
                           write_value_pair_first: ipv4_info[:network_id],

                           cookie: cookie)
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

      flows << flow_create(:default,
                           table: TABLE_ROUTE_EGRESS_INTERFACE,
                           goto_table: TABLE_ARP_TABLE,
                           priority: 20,

                           actions: {
                             :eth_src => mac_info[:mac_address]
                           },
                           match_interface: @id,
                           write_network: ipv4_info[:network_id],
                           cookie: cookie)
    end    

    def flows_for_route_translation(flows)
      [[TABLE_ROUTE_INGRESS_TRANSLATION, TABLE_ROUTER_INGRESS],
       [TABLE_ROUTE_EGRESS_TRANSLATION, TABLE_ROUTE_EGRESS_INTERFACE],
      ].each { |table, goto_table|
        flows << flow_create(:default,
                             table: table,
                             goto_table: goto_table,
                             priority: 90,
                             match_interface: @id)
      }
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
