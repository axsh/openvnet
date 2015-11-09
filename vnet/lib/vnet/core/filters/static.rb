# -*- coding: utf-8 -*-

module Vnet::Core::Filters
  
  class Static < Base2

    def initialize(params)
      super

      @statics = {}
    end

    def log_type
      'filter/static'
    end

    def pretty_static(sf)
      "filter_id:#{sf[:static_id]} ipv4_address:#{sf[:ipv4_address]}"
    end

    def install
      return if @interface_id.nil?

      flows = []

      flows_for_ingress_filtering(flows)
      flows_for_egress_filtering(flows)

      @statics.each { |id, filter|

        match = filter[:match]
        pass = filter[:passthrough]

        debug log_format('installing filter for ' + pretty_static(match)

        rules(match, filter[:protocol]).each { |ingress_rule, egress_rule|
          flows_for_static_ingress_filtering(flows, ingress_rule, pass)
          flows_for_static_egress_filtering(flows, egress_rule, pass)
        }
      }

      @dp_info.add_flows(flows)

    end

    def added_static(static_id, ipv4_address, ipv4_prefix, port, protocol, passthrough)

      filter = {
        :static_id => static_id,
        :ipv4_src_address => ipv4_address[:src],
        :ipv4_dst_address => ipv4_addressc[:dst],
        :ipv4_prefix => ipv4_prefix,
        :port_src_first => port[:src_first],
        :port_dst_first => port[:dst_first],
        :port_src_last => port[:src_last],
        :port_dst_last => port[:dst_last]
      }

      @statics[static_id] = {
        :match => filter,
        :protocol => protocol,
        :passthrough => passthrough
      }

      return if !installed?

      flows = []
      rules(filter, protocol).each { |ingress_rule, egress_rule|
        flows_for_static_ingress_filtering(flows, ingress_rule, passthrough)
        flows_for_static_egress_filtering(flows, egress_rule, passthrough)
      }

      @db_info.add_flows(flows)

    end

    def removed_static(static_id)
    end

    #
    # Internal methods
    #

    private

    def rules(filter, protocol)

      # Using src as the main address until src/dst functionallity is fully implemented

      ipv4_address = filter[:ipv4_src_address]
      port = filter[:port_src_first]
      prefix = filter[:ipv4_prefix]

      case protocol
      when "tcp"  then rule_for_tcp(ipv4_address, port, prefix)
      when "udp"  then rule_for_udp(ipv4_address, port, prefix)
      when "arp"  then rule_for_arp(ipv4_address, prefix)
      when "icmp" then rule_for_icmp(ipv4_address, prefix)
      end
    end

    def rule_for_tcp(ipv4_address, port, prefix)
      if port == 0 || port.nil?
        [
          [{ eth_type: ETH_TYPE_IPV4,
             ipv4_src: ipv4_address,
             ipv4_src_mask: IPV4_BROADCAST << (32 - prefix),
             ip_proto: IPV4_PROTOCOL_TCP,
           },
           { eth_type: ETH_TYPE_IPV4,
             ipv4_dst: ipv4_address,
             ipv4_dst_mask: IPV4_BROADCAST << (32 - prefix),
             ip_proto: IPV4_PROTOCOL_TCP,
           }]
        ]
      else
        [
          [{ eth_type: ETH_TYPE_IPV4,
             ipv4_src: ipv4_address,
             ipv4_src_mask: IPV4_BROADCAST << (32 - prefix),
             ip_proto: IPV4_PROTOCOL_TCP,
             tcp_dst: port
           },
           { eth_type: ETH_TYPE_IPV4,
             ipv4_dst: ipv4_address,
             ipv4_dst_mask: IPV4_BROADCAST << (32 - prefix),
             ip_proto: IPV4_PROTOCOL_TCP,
             tcp_dst: port
           }]
        ]
      end
    end

    def rule_for_udp(ipv4_address, port, prefix)
      if port == 0 || port.nil?
        [
          [{ eth_type: ETH_TYPE_IPV4,
             ipv4_src: ipv4_address,
             ipv4_src_mask: IPV4_BROADCAST << (32 - prefix),
             ip_proto: IPV4_PROTOCOL_UDP,
           },
           { eth_type: ETH_TYPE_IPV4,
             ipv4_dst: ipv4_address,
             ipv4_dst_mask: IPV4_BROADCAST << (32 - prefix),
             ip_proto: IPV4_PROTOCOL_UDP,
           }]
        ]
      else
        [
          [{ eth_type: ETH_TYPE_IPV4,
             ipv4_src: ipv4_address,
             ipv4_src_mask: IPV4_BROADCAST << (32 - prefix),
             ip_proto: IPV4_PROTOCOL_UDP,
             udp_dst: port
           },
           { eth_type: ETH_TYPE_IPV4,
             ipv4_dst: ipv4_address,
             ipv4_dst_mask: IPV4_BROADCAST << (32 - prefix),
             ip_proto: IPV4_PROTOCOL_UDP,
             udp_dst: port
           }]
        ]
      end        
    end

    def rule_for_icmp(ipv4_address, prefix)
      [
        [{ eth_type: ETH_TYPE_IPV4,
           ipv4_src: ipv4_address,
           ipv4_src_mask: IPV4_BROADCAST << (32 - prefix),
           ip_proto: IPV4_PROTOCOL_ICMP
         },
         { eth_type: ETH_TYPE_IPV4,
           ipv4_dst: ipv4_address,
           ipv4_dst_mask: IPV4_BROADCAST << (32 - prefix),
           ip_proto: IPV4_PROTOCOL_ICMP
         }]
      ]
    end

    def rule_for_arp(ipv4_address, prefix)
      [
        [{ eth_type: ETH_TYPE_ARP,
           ipv4_src: ipv4_address,
           ipv4_src_mask: IPV4_BROADCAST << (32 - prefix)
         },
         { eth_type: ETH_TYPE_ARP,
           ipv4_src: ipv4_address,
           ipv4_dst_mask: IPV4_BROADCAST << (32 - prefix)
         }]
      ]
    end

    def flows_for_static_ingress_filtering(flows = [], match, passthrough)
      if passthrough
        flows << flow_create(
          table: TABLE_INTERFACE_INGRESS_FILTER,
          goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
          priority: 10,
          match_interface: @interface_id,
          match: match
        )
      else
        flows << flow_create(
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: 50,
          match_interface: @interface_id,
          match: match
        )
      end
    end

    def flows_for_static_egress_filtering(flows = [], match, passthrough)
      if passthrough
        flows << flow_create(
          table: TABLE_INTERFACE_EGRESS_FILTER,
          goto_table: TABLE_INTERFACE_EGRESS_VALIDATE,
          priority: 10,
          match_interface: @interface_id,
          match: match
        )
      else
        flows << flow_create(
          table: TABLE_INTERFACE_EGRESS_FILTER,
          priority: 50,
          match_interface: @interface_id,
          match: match
        )
      end
    end
  end
end
