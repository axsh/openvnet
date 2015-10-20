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
      @statics.each { |id, filter|

        debug log_format('installing filter for ' + pretty_static(filter[:match]))

        rules(filter[:match], filter[:protocol]).each { |ingress_rule, egress_rule|
          flows_for_ingress_filtering(flows, ingress_rule)
          flows_for_egress_filtering(flows, egress_rule)
        }
      }

      @dp_info.add_flows(flows)

    end

    def added_static(static_id, ipv4_address, ipv4_prefix, port, protocol)

      filter = {
        :static_id => static_id,
        :ipv4_address => ipv4_address,
        :ipv4_prefix => ipv4_prefix,
        :port => port
      }

      @statics[static_id] = {
        :match => filter,
        :protocol => protocol
      }

      return if !installed?

      flows = []

      rules(filter, protocol).each { |ingress_rule, egress_rule|
        flows_for_ingress_filtering(flows, ingress_rule) 
        flows_for_egress_filtering(flows, egress_rule)
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
      case protocol
      when "tcp"  then rule_for_tcp(filter)
      when "udp"  then rule_for_udp(filter)
      when "arp"  then rule_for_arp(filter)
      when "icmp" then rule_for_icmp(filter)
      end
    end

    def rule_for_tcp(filter)
      if filter[:port] > 0
        [
          [{ eth_type: ETH_TYPE_IPV4,
             ipv4_src: filter[:ipv4_address],
             ipv4_src_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
             ip_proto: IPV4_PROTOCOL_TCP,
             tcp_dst: filter[:port]
           },
           { eth_type: ETH_TYPE_IPV4,
             ipv4_dst: filter[:ipv4_address],
             ipv4_dst_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
             ip_proto: IPV4_PROTOCOL_TCP,
             tcp_dst: filter[:port]
           }]
        ]
      else
        [
          [{ eth_type: ETH_TYPE_IPV4,
             ipv4_src: filter[:ipv4_address],
             ipv4_src_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
             ip_proto: IPV4_PROTOCOL_TCP,
           },
           { eth_type: ETH_TYPE_IPV4,
             ipv4_dst: filter[:ipv4_address],
             ipv4_dst_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
             ip_proto: IPV4_PROTOCOL_TCP,
           }]
        ]
      end
    end

    def rule_for_udp(filter)
      if filter[:port] > 0
        [
          [{ eth_type: ETH_TYPE_IPV4,
             ipv4_src: filter[:ipv4_address],
             ipv4_src_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
             ip_proto: IPV4_PROTOCOL_UDP,
             udp_dst: filter[:port]
           },
           { eth_type: ETH_TYPE_IPV4,
             ipv4_dst: filter[:ipv4_address],
             ipv4_dst_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
             ip_proto: IPV4_PROTOCOL_UDP,
             udp_dst: filter[:port]
           }]
        ]
      else
        [
          [{ eth_type: ETH_TYPE_IPV4,
             ipv4_src: filter[:ipv4_address],
             ipv4_src_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
             ip_proto: IPV4_PROTOCOL_UDP,
           },
           { eth_type: ETH_TYPE_IPV4,
             ipv4_dst: filter[:ipv4_address],
             ipv4_dst_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
             ip_proto: IPV4_PROTOCOL_UDP,
           }]
        ]
      end        
    end

    def rule_for_icmp(filter)
      [
        [{ eth_type: ETH_TYPE_IPV4,
           ipv4_src: filter[:ipv4_address],
           ipv4_src_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
           ip_proto: IPV4_PROTOCOL_ICMP
         },
         { eth_type: ETH_TYPE_IPV4,
           ipv4_dst: filter[:ipv4_address],
           ipv4_dst_mask: IPV4_BROADCAST << (32 - filter[:ipv4_prefix]),
           ip_proto: IPV4_PROTOCOL_ICMP
         }]
      ]
    end

    def rule_for_arp(filter)
      [
        [{ eth_type: ETH_TYPE_ARP },
         { eth_type: ETH_TYPE_ARP }]
      ]
    end

    def flows_for_ingress_filtering(flows = [], match)
        if @ingress_passthrough
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

    def flows_for_egress_filtering(flows = [], match)
        if @egress_passthrough
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
