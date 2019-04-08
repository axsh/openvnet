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
      flows << flow_create(table: TABLE_INTERFACE_EGRESS_CLASSIFIER,
                           goto_table: @enabled_filtering ? TABLE_INTERFACE_EGRESS_STATEFUL : TABLE_INTERFACE_EGRESS_VALIDATE,
                           priority: 30,
                           match_interface: @id,
                           cookie: cookie
                          )
    end

    def flows_for_disabled_filtering(flows = [])
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_FILTER,
                           goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: PRIORITY_FILTER_SKIP,
                           match_interface: @id,
                           cookie: self.cookie
                          )
    end

    def flows_for_interface_mac(flows, mac_info)
      mac_cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])
      mac_address = mac_info[:mac_address]
      segment_id = mac_info[:segment_id]

      #
      # Anti-spoof:
      #
      [{ :eth_src => mac_address,
       },{
         :eth_type => 0x0806,
         :arp_sha => mac_address,
       }
      ].each { |match|
        # Currently add to ingress_nw_if table since we do not
        # yet support segments.
        flows << flow_create(table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                             priority: 50,
                             match: match,
                             #match_segment: mac_info[:segment_id],
                             cookie: cookie)

      }

      if segment_id
        flows << flow_create(table: TABLE_INTERFACE_EGRESS_VALIDATE,
                             goto_table: TABLE_SEGMENT_SRC_CLASSIFIER,
                             priority: 30,
                             match: { :eth_src => mac_address },
                             match_interface: @id,
                             write_segment: segment_id,
                             cookie: cookie)
        flows << flow_create(table: TABLE_SEGMENT_DST_MAC_LOOKUP,
                             goto_table: TABLE_INTERFACE_INGRESS_FILTER,
                             priority: 60,
                             match: { :eth_dst => mac_address },
                             match_segment: segment_id,
                             write_interface: @id,
                             cookie: cookie)
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
      [{ :eth_type => 0x0800,
         :eth_src => mac_address,
         :ipv4_src => IPV4_ZERO
       }, {
         :eth_type => 0x0800,
         :eth_src => mac_address,
         :ipv4_src => ipv4_address
       }, {
         :eth_type => 0x0806,
         :eth_src => mac_address,
         :arp_sha => mac_address,
         :arp_spa => ipv4_address
       }].each { |match|
        if segment_id
          flows << flow_create(table: TABLE_INTERFACE_EGRESS_VALIDATE,
                               goto_table: TABLE_SEGMENT_SRC_CLASSIFIER,
                               priority: 40,
                               match: match,
                               match_interface: @id,
                               write_segment: segment_id,
                               cookie: cookie)
        else
          flows << flow_create(table: TABLE_INTERFACE_EGRESS_VALIDATE,
                               goto_table: TABLE_NETWORK_CONNECTION,
                               priority: 40,
                               match: match,
                               match_interface: @id,
                               write_network: network_id,
                               cookie: cookie)
        end
      }

      #
      # IPv4
      #
      flows << flow_create(table: TABLE_ARP_TABLE,
                           goto_table: TABLE_NETWORK_DST_CLASSIFIER,
                           priority: 40,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_dst => ipv4_address,
                           },
                           match_network: network_id,
                           actions: {
                             :eth_dst => mac_address,
                           },
                           cookie: cookie)

      [{:eth_type => 0x0800,
        :eth_dst => mac_address,
        :ipv4_dst => ipv4_address,
       },{
        :eth_type => 0x0806,
        :eth_dst => mac_address,
        :arp_tha => mac_address,
        :arp_tpa => ipv4_address
       }].each { |match|
        flows << flow_create(table: TABLE_NETWORK_DST_MAC_LOOKUP,
                             goto_table: TABLE_INTERFACE_INGRESS_FILTER,
                             priority: 60,
                             match: match,
                             match_network: network_id,
                             write_interface: @id,
                             cookie: cookie)
      }

      #
      # Anti-spoof:
      #

      # TODO: This doesn't currently support global interfaces, as
      # such it is for the time being disabled.

      if mode == :vif || mode == :host
        [{ :eth_type => 0x0806,
            :arp_spa => ipv4_address,
          },{
            :eth_type => 0x0800,
            :ipv4_src => ipv4_address,
          }
        ].each { |match|
          flows << flow_create(table: TABLE_INTERFACE_INGRESS_NW_DPNW,
                               priority: 90,
                               match: match,
                               match_value_pair_first: network_id,
                               cookie: cookie)
        }
      end
    end

    def flows_for_router_ingress_mac(flows, mac_info)
    end

    def flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      if ipv4_info[:enable_routing] != true
        flows << flow_create(table: TABLE_ROUTE_INGRESS_INTERFACE,
                             goto_table: TABLE_NETWORK_DST_CLASSIFIER,
                             priority: 20,
                             match: {
                               :eth_type => 0x0800,
                               :eth_dst => mac_info[:mac_address],
                               :ipv4_dst => ipv4_info[:ipv4_address]
                             },
                             match_network: ipv4_info[:network_id],
                             cookie: cookie)
      end

      flows << flow_create(table: TABLE_ROUTE_INGRESS_INTERFACE,
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

      flows << flow_create(table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                           goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                           priority: 20,

                           match: {
                             :eth_dst => mac_info[:mac_address]
                           },

                           write_value_pair_second: ipv4_info[:network_id],

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
                             :eth_src => mac_info[:mac_address]
                           },

                           write_value_pair_second: ipv4_info[:network_id],

                           cookie: cookie)
    end

    def flows_for_router_egress_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      flows << flow_create(table: TABLE_INTERFACE_EGRESS_VALIDATE,
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
      flows << flow_create(table: TABLE_INTERFACE_EGRESS_MAC,
                           goto_table: TABLE_ARP_TABLE,
                           priority: 20,
                           match: {
                             :eth_src => mac_info[:mac_address]
                           },
                           match_network: ipv4_info[:network_id],
                           cookie: cookie)
      flows << flow_create(table: TABLE_ROUTE_EGRESS_LOOKUP,
                           goto_table: TABLE_ROUTE_EGRESS_TRANSLATION,
                           priority: 20,

                           match_value_pair_first: @id,

                           clear_all: true,
                           write_reflection: true,
                           write_interface: @id,

                           cookie: cookie)

      flows << flow_create(table: TABLE_ROUTE_EGRESS_INTERFACE,
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
      [[TABLE_ROUTE_INGRESS_TRANSLATION, TABLE_ROUTER_INGRESS_LOOKUP],
       [TABLE_ROUTE_EGRESS_TRANSLATION, TABLE_ROUTE_EGRESS_INTERFACE],
      ].each { |table, goto_table|
        flows << flow_create(table: table,
                             goto_table: goto_table,
                             priority: 90,
                             match_interface: @id)
      }
    end

    def flows_for_mac2mac_mac(flows, mac_info)
      segment_id = mac_info[:segment_id] || return
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      [{ :eth_type => 0x0800,
         :eth_dst => mac_info[:mac_address]
       }, {
         :eth_type => 0x0806,
         :eth_dst => mac_info[:mac_address]
       }].each { |match|
        flows << flow_create(table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                             goto_table: TABLE_INTERFACE_INGRESS_IF_SEG,
                             priority: 30,

                             match: match,

                             write_value_pair_second: mac_info[:segment_id],

                             cookie: cookie)
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
        flows << flow_create(table: TABLE_INTERFACE_INGRESS_LOOKUP_IF_NIL,
                             goto_table: TABLE_INTERFACE_INGRESS_IF_NW,
                             priority: 40,

                             match: match,
                             
                             write_value_pair_second: ipv4_info[:network_id],

                             cookie: cookie)
      }
    end

  end

end
