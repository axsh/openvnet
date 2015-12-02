# -*- coding: utf-8 -*-

module Vnet::Core::Filters
  
  class Static < Base2

    BASE_PRIORITY = 20

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
      super

      flows = []

      @statics.each { |id, filter|

        match = filter[:match]
        passthrough = filter[:passthrough]

        debug log_format('installing filter for ' + pretty_static(match))

        rules(match, filter[:protocol]).each { |ingress_rule, egress_rule|
          flows_for_static_ingress_filtering(flows, ingress_rule, passthrough) { |base|
            base + priority(match[:ipv4_src_prefix], match[:port_src], passthrough)
          }

          flows_for_static_egress_filtering(flows, egress_rule, passthrough) { |base|
            base + priority(match[:ipv4_dst_prefix], match[:port_dst], passthrough)
          }
        }
      }
      @dp_info.add_flows(flows)

    end

    def added_static(static_id, ipv4, port, protocol, passthrough)

      filter = {
        :static_id => static_id,
        :ipv4_src_address => ipv4[:src_address],
        :ipv4_dst_address => ipv4[:dst_address],
        :ipv4_src_prefix => ipv4[:src_prefix],
        :ipv4_dst_prefix => ipv4[:dst_prefix],
        :port_src => port[:src],
        :port_dst => port[:dst],
      }

      @statics[static_id] = {
        :match => filter,
        :protocol => protocol,
        :passthrough => passthrough
      }

      return if !installed?

      flows = []
      rules(filter, protocol).each { |ingress_rule, egress_rule|
        flows_for_static_ingress_filtering(flows, ingress_rule, passthrough) { |base|
          base + priority(ipv4[:src_prefix], port[:src], passthrough)
        }

        flows_for_static_egress_filtering(flows, egress_rule, passthrough) { |base|
          base + priority(ipv4[:dst_prefix], port[:dst], passthrough)
        }
      }
      @dp_info.add_flows(flows)

    end

    def removed_static(static_id)
      static = @statics.delete(static_id)
      return if !installed?

      match = static[:match]

      debug log_format('removing filter for ' + pretty_static(match))

      rules(match, static[:protocol]).each { |ingress_rule, egress_rule|
        @dp_info.del_flows(table_id: TABLE_INTERFACE_INGRESS_FILTER,
                           cookie: self.cookie,
                           cookie_mask: Vnet::Constants::OpenflowFlows::COOKIE_MASK,
                           match: ingress_rule)

        @dp_info.del_flows(table_id: TABLE_INTERFACE_EGRESS_FILTER,
                           cookie: self.cookie,
                           cookie_mask: Vnet::Constants::OpenflowFlows::COOKIE_MASK,
                           match: egress_rule)
      }
    end

    #
    # Internal methods
    #

    private

    def priority(prefix, port, passthrough)
      (prefix << 1) + (passthrough ? 1 : 0) + ((port.nil? || port == 0) ? 0 : 2)
    end

    def rules(filter, protocol)

      # Using src as the main address until src/dst functionallity is fully implemented

      ipv4_address = filter[:ipv4_src_address]
      port = filter[:port_src]
      prefix = filter[:ipv4_src_prefix]

      case protocol
      when "tcp"  then rule_for_tcp(ipv4_address, port, prefix)
      when "udp"  then rule_for_udp(ipv4_address, port, prefix)
      when "arp"  then rule_for_arp(ipv4_address, prefix)
      when "icmp" then rule_for_icmp(ipv4_address, prefix)
      when "all"  then rule_for_all
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
           arp_spa: ipv4_address,
           arp_spa_mask: IPV4_BROADCAST << (32 - prefix)
         },
         { eth_type: ETH_TYPE_ARP,
           arp_tpa: ipv4_address,
           arp_tpa_mask: IPV4_BROADCAST << (32 - prefix)
         }]
      ]
    end

    def flows_for_static_ingress_filtering(flows = [], match, passthrough)
      flows << flow_create(
        table: TABLE_INTERFACE_INGRESS_FILTER,
        goto_table: passthrough ? TABLE_OUT_PORT_INTERFACE_INGRESS : nil,
        priority: yield(BASE_PRIORITY),
        match_interface: @interface_id,
        match: match
      )
    end

    def flows_for_static_egress_filtering(flows = [], match, passthrough)
      flows << flow_create(
        table: TABLE_INTERFACE_EGRESS_FILTER,
        goto_table: passthrough ? TABLE_INTERFACE_EGRESS_VALIDATE : nil,
        priority: yield(BASE_PRIORITY),
        match_interface: @interface_id,
        match: match
      )
    end
  end
end
