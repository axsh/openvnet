# -*- coding: utf-8 -*-

module Vnet::Core::Interfaces

  # Base class for regular interfaces.

  class IfBase < Base

    def enable_filtering2
      return if @enable_filtering

      @enabled_filtering = true
    end

    def disable_filtering2
      return if !@enable_filtering

      @enabled_filtering = false
      @dp_info.add_flows flows_for_disabled_filtering
    end
    #
    # Internal methods:
    #

    private

    def flows_for_classifiers(flows = [])
      flows << flow_create(table: TABLE_INTERFACE_EGRESS_CLASSIFIER_IF_NIL,
                           goto_table: @enabled_filtering ? TABLE_INTERFACE_EGRESS_STATEFUL_IF_NIL : TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL,
                           priority: 30,

                           match_first: @id)
    end

    def flows_for_disabled_filtering(flows = [])
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_FILTER_IF_NIL,
                           goto_table: TABLE_OUT_PORT_INGRESS_IF_NIL,
                           priority: PRIORITY_FILTER_SKIP,

                           match_first: @id)
    end

    def flows_for_interface_mac(flows, mac_info)
      mac_cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])
      mac_address = mac_info[:mac_address]
      segment_id = mac_info[:segment_id]

      #
      # Anti-spoof:
      #
      [{ source_mac_address: mac_address,
       },{
         ether_type: ETH_TYPE_ARP,
         arp_sha: mac_address,
       }
      ].each { |match|
        # Currently add to ingress_nw_if table since we do not
        # yet support segments.
        flows << flow_create(table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                             priority: 50,
                             match: match,
                             #match_segment: mac_info[:segment_id]
                            )

      }

      if segment_id
        flows << flow_create(table: TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL,
                             goto_table: TABLE_SEGMENT_SRC_CLASSIFIER_SEG_NIL,
                             priority: 30,

                             match: {
                               source_mac_address: mac_address
                             },
                             match_first: @id,

                             write_first: segment_id,
                            )
        flows << flow_create(table: TABLE_SEGMENT_DST_MAC_LOOKUP_SEG_NW,
                             goto_table: TABLE_INTERFACE_INGRESS_FILTER_IF_NIL,
                             priority: 60,

                             match: {
                               destination_mac_address: mac_address
                             },
                             match_first: segment_id,

                             write_first: @id,
                             write_second: 0,
                            )
      end
    end

    def flows_for_interface_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      segment_id = mac_info[:segment_id]
      network_id = ipv4_info[:network_id]

      mac_address = mac_info[:mac_address]
      ipv4_address = ipv4_info[:ipv4_address]

      #
      # Validate
      #
      [{ ether_type: ETH_TYPE_IPV4,
         source_mac_address: mac_address,
         ipv4_source_address: IPV4_ZERO
       }, {
         ether_type: ETH_TYPE_IPV4,
         source_mac_address: mac_address,
         ipv4_source_address: ipv4_address
       }, {
         ether_type: ETH_TYPE_ARP,
         source_mac_address: mac_address,
         arp_sha: mac_address,
         arp_spa: ipv4_address
       }].each { |match|
        if segment_id
          flows << flow_create(table: TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL,
                               goto_table: TABLE_SEGMENT_SRC_CLASSIFIER_SEG_NIL,
                               priority: 40,

                               match: match,
                               match_first: @id,

                               write_first: segment_id,
                               write_second: 0,

                               cookie: cookie)
        else
          flows << flow_create(table: TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL,
                               goto_table: TABLE_NETWORK_SRC_CLASSIFIER_NW_NIL,
                               priority: 40,

                               match: match,
                               match_first: @id,

                               write_first: network_id,

                               cookie: cookie)
        end
      }

      #
      # IPv4
      #
      flows << flow_create(table: TABLE_ARP_TABLE_NW_NIL,
                           goto_table: TABLE_NETWORK_DST_CLASSIFIER_NW_NIL,
                           priority: 40,

                           match: {
                             ether_type: ETH_TYPE_IPV4,
                             ipv4_destination_address: ipv4_address,
                           },
                           match_first: network_id,

                           actions: {
                             destination_mac_address: mac_address,
                           },
                           
                           cookie: cookie)

      [{ether_type: ETH_TYPE_IPV4,
        destination_mac_address: mac_address,
        ipv4_destination_address: ipv4_address,
       },{
        ether_type: ETH_TYPE_ARP,
        destination_mac_address: mac_address,
        arp_tha: mac_address,
        arp_tpa: ipv4_address
       }].each { |match|
        flows << flow_create(table: TABLE_NETWORK_DST_MAC_LOOKUP_NIL_NW,
                             goto_table: TABLE_INTERFACE_INGRESS_FILTER_IF_NIL,
                             priority: 60,

                             match: match,
                             match_second: network_id,

                             write_first: @id,
                             write_second: 0,
                            )
      }

      #
      # Anti-spoof:
      #

      # TODO: This doesn't currently support global interfaces, as
      # such it is for the time being disabled.

      if mode == :vif || mode == :host
        [{ ether_type: ETH_TYPE_ARP,
           arp_spa: ipv4_address,
         },{
           ether_type: ETH_TYPE_IPV4,
           ipv4_source_address: ipv4_address,
         }
        ].each { |match|
          flows << flow_create(table: TABLE_INTERFACE_INGRESS_NW_DPNW,
                               priority: 90,
                               match: match,
                               match_first: network_id,
                               cookie: cookie)
        }
      end
    end

    def flows_for_router_ingress_mac(flows, mac_info)
    end

    def flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      if ipv4_info[:enable_routing] != true
        flows << flow_create(table: TABLE_ROUTE_INGRESS_INTERFACE_NW_NIL,
                             goto_table: TABLE_NETWORK_DST_CLASSIFIER_NW_NIL,
                             priority: 20,
                             
                             match: {
                               ether_type: ETH_TYPE_IPV4,
                               destination_mac_address: mac_info[:mac_address],
                               ipv4_destination_address: ipv4_info[:ipv4_address]
                             },
                             match_first: ipv4_info[:network_id],

                             cookie: cookie)
      end

      flows << flow_create(table: TABLE_ROUTE_INGRESS_INTERFACE_NW_NIL,
                           goto_table: TABLE_ROUTE_INGRESS_TRANSLATION_IF_NIL,
                           priority: 10,

                           match: {
                             ether_type: ETH_TYPE_IPV4,
                             destination_mac_address: mac_info[:mac_address]
                           },
                           match_first: ipv4_info[:network_id],
                           write_first: @id,

                           cookie: cookie)
    end

    # TODO: Rename:
    def flows_for_router_ingress_mac2mac_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                           priority: 20,

                           match: {
                             destination_mac_address: mac_info[:mac_address]
                           },

                           write_second: ipv4_info[:network_id],

                           cookie: cookie)

      # Handle packets from simulated interfaces that can be on
      # multiple datapaths.
      #
      # Should be improved to use unique mac addresses in the case of
      # mac2mac.
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                           priority: 60,

                           match: {
                             source_mac_address: mac_info[:mac_address]
                           },

                           write_second: ipv4_info[:network_id],

                           cookie: cookie)
    end

    def flows_for_router_egress_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      flows << flow_create(table: TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL,
                           goto_table: TABLE_INTERFACE_EGRESS_ROUTES_IF_NIL,
                           priority: 20,

                           match: {
                             source_mac_address: mac_info[:mac_address]
                           },
                           match_first: @id,
                           
                           cookie: cookie)
    end

    def flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      #
      # Not needed unless egress routing is used:
      #

      # TODO: Currently only one mac address / network is supported.
      flows << flow_create(table: TABLE_INTERFACE_EGRESS_ROUTES_IF_NW,
                           goto_table: TABLE_ARP_TABLE_NW_NIL,
                           priority: 20,

                           match: {
                             source_mac_address: mac_info[:mac_address]
                           },
                           match_first: @id,
                           match_second: ipv4_info[:network_id],

                           write_first: ipv4_info[:network_id],
                           write_second: 0,

                           cookie: cookie)
      flows << flow_create(table: TABLE_ROUTE_EGRESS_LOOKUP_IF_RL,
                           goto_table: TABLE_ROUTE_EGRESS_TRANSLATION_IF_NIL,
                           priority: 20,

                           match_first: @id,

                           write_reflection: true,
                           write_second: 0,

                           cookie: cookie)

      flows << flow_create(table: TABLE_ROUTE_EGRESS_INTERFACE_IF_NIL,
                           goto_table: TABLE_ARP_TABLE_NW_NIL,
                           priority: 20,

                           match_first: @id,

                           actions: {
                             source_mac_address: mac_info[:mac_address]
                           },
                           write_first: ipv4_info[:network_id],
                           write_second: 0,

                           cookie: cookie)
    end

    def flows_for_route_translation(flows)
      [[TABLE_ROUTE_INGRESS_TRANSLATION_IF_NIL, TABLE_ROUTER_INGRESS_LOOKUP_IF_NIL],
       [TABLE_ROUTE_EGRESS_TRANSLATION_IF_NIL, TABLE_ROUTE_EGRESS_INTERFACE_IF_NIL],
      ].each { |table, goto_table|
        flows << flow_create(table: table,
                             goto_table: goto_table,
                             priority: 90,
                             match_first: @id,
                            )
      }
    end

    def flows_for_mac2mac_mac(flows, mac_info)
      segment_id = mac_info[:segment_id] || return
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      [{ ether_type: ETH_TYPE_IPV4,
         destination_mac_address: mac_info[:mac_address]
       }, {
         ether_type: ETH_TYPE_ARP,
         destination_mac_address: mac_info[:mac_address]
       }].each { |match|
        flows << flow_create(table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                             goto_table: TABLE_INTERFACE_INGRESS_IF_SEG,
                             priority: 30,

                             match: match,

                             write_second: mac_info[:segment_id],

                             cookie: cookie)
      }
    end

    def flows_for_mac2mac_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      [{ ether_type: ETH_TYPE_IPV4,
         destination_mac_address: mac_info[:mac_address],
         ipv4_destination_address: ipv4_info[:ipv4_address]
       }, {
         ether_type: ETH_TYPE_ARP,
         destination_mac_address: mac_info[:mac_address],
         arp_tpa: ipv4_info[:ipv4_address]
       }].each { |match|
        flows << flow_create(table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                             goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                             priority: 40,

                             match: match,
                             
                             write_second: ipv4_info[:network_id],

                             cookie: cookie)
      }
    end

  end

end
