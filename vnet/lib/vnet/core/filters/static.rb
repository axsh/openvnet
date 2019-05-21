# -*- coding: utf-8 -*-

module Vnet::Core::Filters
  class Static < Base

    EGRESS_IDLE_TIMEOUT  = 600
    INGRESS_IDLE_TIMEOUT = 1800

    def initialize(params)
      super
      @statics = {}
    end

    def log_type
      'filter/static'
    end

    def install
      super

      flows = []

      @statics.each { |id, filter|
        debug log_format_h('installing filter', filter[:match])

        flows_for_static(flows, filter[:protocol], filter[:match], filter[:action])
      }

      @dp_info.add_flows(flows)
    end

    def added_static(params)
      static_id = get_param_id(params, :static_id)

      @statics[static_id] = {
        match: {
          static_id: static_id,
          src_address: get_param_ipv4_address(params, :src_address),
          dst_address: get_param_ipv4_address(params, :dst_address),
          src_prefix: get_param_int(params, :src_prefix),
          dst_prefix: get_param_int(params, :dst_prefix),
          port_src: get_param_int(params, :port_src, false),
          port_dst: get_param_int(params, :port_dst, false)
        },

        # TODO: Replace with symbol lookup.
        protocol: get_param_string(params, :protocol),
        action: get_param_string(params, :action)
      }.tap { |static|
        next if !installed?

        flows = []
        flows_for_static(flows, static[:protocol], static[:match], static[:action])

        @dp_info.add_flows(flows)
      }
    end

    def removed_static(params)
      @statics.delete(get_param_id(params, :static_id)).tap { |static|
        next if !installed? || static.nil?

        debug log_format_h('removing filter', static[:match])

        # TODO: Need to include priority when deleting.
        rules(static[:match], static[:protocol]).tap { |egress_rule, ingress_rule|
          @dp_info.del_flows(table_id: TABLE_INTERFACE_EGRESS_FILTER_IF_NIL,
                             cookie: self.cookie,
                             cookie_mask: Vnet::Constants::OpenflowFlows::COOKIE_MASK,

                             match: egress_rule
                            )
          @dp_info.del_flows(table_id: TABLE_INTERFACE_INGRESS_FILTER_IF_NIL,
                             cookie: self.cookie,
                             cookie_mask: Vnet::Constants::OpenflowFlows::COOKIE_MASK,

                             match: ingress_rule
                            )
        }
      }
    end

    def packet_in(message)
      return if !installed?

      egress_match, ingress_match = match_from_message(message)
      return if egress_match.nil? || ingress_match.nil?

      flows = []

      flows << flow_create(table: TABLE_INTERFACE_EGRESS_STATEFUL_IF_NIL,
                           goto_table: TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL,
                           priority: PRIORITY_FILTER_STATEFUL,
                           idle_timeout: EGRESS_IDLE_TIMEOUT,
                           
                           match: egress_match,
                           match_first: @interface_id,
                          )
      flows << flow_create(table: TABLE_INTERFACE_INGRESS_FILTER_IF_NIL,
                           goto_table: TABLE_OUT_PORT_INGRESS_IF_NIL,
                           priority: PRIORITY_FILTER_STATEFUL,
                           idle_timeout: INGRESS_IDLE_TIMEOUT,
                           
                           match: ingress_match,
                           match_first: @interface_id,
                          )

      @dp_info.add_flows(flows)
      @dp_info.send_packet_out(message, OFPP_TABLE)
    end

    #
    # Internal methods
    #

    private

    def any_address?(address, prefix)
      address == 0 && prefix == 0
    end

    # TODO: Change the priority ordering so that the largest prefix of
    # either src or dst is always checked first.
    def priority_for_static(src_prefix:, dst_prefix:, port_src:, port_dst:, **)
      20 + ((dst_prefix * 2) + ((port_dst.nil? || port_dst == 0) ? 0 : 1)) * 66 +
        (src_prefix * 2) + ((port_src.nil? || port_src == 0) ? 0 : 1)
    end

    def rules(filter, protocol)
      case protocol
      when 'tcp'  then rule_for_tcp(filter)
      when 'udp'  then rule_for_udp(filter)
      when 'arp'  then rule_for_arp(filter)
      when 'icmp' then rule_for_ipv4(IPV4_PROTOCOL_ICMP, filter)
      when 'ip'   then rule_for_ipv4(nil, filter)
      end
    end

    def rule_for_ipv4(ip_proto, src_address:, dst_address:, src_prefix:, dst_prefix:, **)
      egress_match = {
        ether_type: ETH_TYPE_IPV4,
        ip_protocol: ip_proto
      }.tap { |match|
        if !any_address?(src_address, src_prefix)
          match[:ipv4_destination_address] = src_address
          match[:ipv4_destination_address_mask] = IPV4_BROADCAST.mask(src_prefix)
        end

        if !any_address?(dst_address, dst_prefix)
          match[:ipv4_source_address] = dst_address
          match[:ipv4_source_address_mask] = IPV4_BROADCAST.mask(dst_prefix)
        end
      }

      ingress_match = {
        ether_type: ETH_TYPE_IPV4,
        ip_protocol: ip_proto
      }.tap { |match|
        if !any_address?(src_address, src_prefix)
          match[:ipv4_source_address] = src_address
          match[:ipv4_source_address_mask] = IPV4_BROADCAST.mask(src_prefix)
        end

        if !any_address?(dst_address, dst_prefix)
          match[:ipv4_destination_address] = dst_address
          match[:ipv4_destination_address_mask] = IPV4_BROADCAST.mask(dst_prefix)
        end
      }

      return [egress_match, ingress_match]
    end

    def rule_for_tcp(port_src:, port_dst:, **other)
      rule_for_ipv4(IPV4_PROTOCOL_TCP, other).tap { |egress_match, ingress_match|
        if port_src && port_src != 0
          ingress_match[:tcp_src] = port_src
          egress_match[:tcp_dst] = port_src
        end

        if port_dst && port_dst != 0
          ingress_match[:tcp_dst] = port_dst
          egress_match[:tcp_src] = port_dst
        end
      }
    end

    def rule_for_udp(port_src:, port_dst:, **other)
      rule_for_ipv4(IPV4_PROTOCOL_UDP, other).tap { |egress_match, ingress_match|
        if port_src && port_src != 0
          ingress_match[:udp_src] = port_src
          egress_match[:udp_dst] = port_src
        end

        if port_dst && port_dst != 0
          ingress_match[:udp_dst] = port_dst
          egress_match[:udp_src] = port_dst
        end
      }
    end
    
    def rule_for_arp(src_address:, dst_address:, src_prefix:, dst_prefix:, **)
      egress_match = {
        ether_type: ETH_TYPE_ARP,
      }.tap { |match|
        if !any_address?(src_address, src_prefix)
          match[:arp_tpa] = src_address
          match[:arp_tpa_mask] = IPV4_BROADCAST.mask(src_prefix)
        end

        if !any_address?(dst_address, dst_prefix)
          match[:arp_spa] = dst_address
          match[:arp_spa_mask] = IPV4_BROADCAST.mask(dst_prefix)
        end
      }

      ingress_match = {
        ether_type: ETH_TYPE_ARP,
      }.tap { |match|
        if !any_address?(src_address, src_prefix)
          match[:arp_spa] = src_address
          match[:arp_spa_mask] = IPV4_BROADCAST.mask(src_prefix)
        end

        if !any_address?(dst_address, dst_prefix)
          match[:arp_tpa] = dst_address
          match[:arp_tpa_mask] = IPV4_BROADCAST.mask(dst_prefix)
        end
      }

      return [egress_match, ingress_match]
    end

    def flows_for_static(flows, protocol, filter, action)
      rules(filter, protocol).tap { |egress_rule, ingress_rule|
        flow_base = {
          priority: priority_for_static(filter),
          match_first: @interface_id,
        }

        case action
        when 'conn'
          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_EGRESS_FILTER_IF_NIL,
                                               match: egress_rule,
                                               actions: { output: :controller }))
        when 'pass'
          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_INGRESS_FILTER_IF_NIL,
                                               goto_table: TABLE_OUT_PORT_INGRESS_IF_NIL,
                                               match: ingress_rule))
          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_EGRESS_FILTER_IF_NIL,
                                               goto_table: TABLE_INTERFACE_EGRESS_VALIDATE_IF_NIL,
                                               match: egress_rule))
        when 'drop'
          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_INGRESS_FILTER_IF_NIL,
                                               goto_table: nil,
                                               match: ingress_rule))
          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_EGRESS_FILTER_IF_NIL,
                                               goto_table: nil,
                                               match: egress_rule))
        end
      }
    end

    def match_from_message(message)
      return if !message.ipv4?

      egress_match = {
        ether_type: ETH_TYPE_IPV4,
        ipv4_source_address: message.ipv4_source_address,
        ipv4_destination_address: message.ipv4_destination_address
      }
      ingress_match = {
        ether_type: ETH_TYPE_IPV4,
        ipv4_source_address: message.ipv4_destination_address,
        ipv4_destination_address: message.ipv4_source_address
      }

      case
      when message.tcp?
        egress_match.merge!(ip_protocol: IPV4_PROTOCOL_TCP,
                            tcp_src: message.tcp_src,
                            tcp_dst: message.tcp_dst)
        ingress_match.merge!(ip_protocol: IPV4_PROTOCOL_TCP,
                             tcp_src: message.tcp_dst,
                             tcp_dst: message.tcp_src)
      when message.udp?
        egress_match.merge!(ip_protocol: IPV4_PROTOCOL_UDP,
                            udp_src: message.udp_src,
                            udp_dst: message.udp_dst)
        ingress_match.merge!(ip_protocol: IPV4_PROTOCOL_UDP,
                             udp_src: message.udp_dst,
                             udp_dst: message.udp_src)
      when message.icmpv4?
        egress_match.merge!(ip_protocol: IPV4_PROTOCOL_ICMP)
        ingress_match.merge!(ip_protocol: IPV4_PROTOCOL_ICMP)
      when message.arpv4?
        egress_match.merge!(ip_protocol: IPV4_PROTOCOL_ARP)
        ingress_match.merge!(ip_protocol: IPV4_PROTOCOL_ARP)
      end

      return egress_match, ingress_match
    end

  end
end
