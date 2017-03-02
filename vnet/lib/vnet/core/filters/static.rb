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
          ipv4_src_address: get_param_ipv4_address(params, :ipv4_src_address),
          ipv4_dst_address: get_param_ipv4_address(params, :ipv4_dst_address),
          ipv4_src_prefix: get_param_int(params, :ipv4_src_prefix),
          ipv4_dst_prefix: get_param_int(params, :ipv4_dst_prefix),
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
          @dp_info.del_flows(table_id: TABLE_INTERFACE_EGRESS_FILTER,
            cookie: self.cookie,
            cookie_mask: Vnet::Constants::OpenflowFlows::COOKIE_MASK,
            match: egress_rule)

          @dp_info.del_flows(table_id: TABLE_INTERFACE_INGRESS_FILTER,
            cookie: self.cookie,
            cookie_mask: Vnet::Constants::OpenflowFlows::COOKIE_MASK,
            match: ingress_rule)
        }
      }
    end

    def packet_in(message)
      return if !installed?

      info log_format_h('packet_in', in_port: message.in_port, eth_dst: message.eth_dst, eth_src: message.eth_src)

      egress_match, ingress_match = match_from_message(message)
      return if egress_match.nil? || ingress_match.nil?

      info log_format_h('egress_match', egress_match)
      info log_format_h('ingress_match', ingress_match)

      flows = []

      flows << flow_create(table: TABLE_INTERFACE_EGRESS_FILTER,
                           goto_table: TABLE_INTERFACE_EGRESS_VALIDATE,
                           priority: max_priority_for_static,
                           match_interface: @interface_id,
                           match: egress_match)

      flows << flow_create(table: TABLE_INTERFACE_INGRESS_FILTER,
                           goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: max_priority_for_static,
                           match_interface: @interface_id,
                           match: ingress_match)

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

    def max_priority_for_static
      20 + (65 * 66)
    end

    # TODO: Change the priority ordering so that the largest prefix of
    # either src or dst is always checked first.
    def priority_for_static(ipv4_src_prefix:, ipv4_dst_prefix:, port_src:, port_dst:, **)
      20 + ((ipv4_dst_prefix * 2) + ((port_dst.nil? || port_dst == 0) ? 0 : 1)) * 66 +
        (ipv4_src_prefix * 2) + ((port_src.nil? || port_src == 0) ? 0 : 1)
    end

    def rules(filter, protocol)
      ipv4_address = filter[:ipv4_dst_address]
      port = filter[:port_dst]
      prefix = filter[:ipv4_dst_prefix]

      case protocol
      when 'tcp'  then rule_for_tcp(filter)
      when 'udp'  then rule_for_udp(filter)
      when 'arp'  then rule_for_arp(filter)
      when 'icmp' then rule_for_ipv4(IPV4_PROTOCOL_ICMP, filter)
      when 'all'  then rule_for_ipv4(nil, filter)
      end
    end

    # TODO: Remove the unnecessary ipv4_ prefix.
    def rule_for_ipv4(ip_proto, ipv4_src_address:, ipv4_dst_address:, ipv4_src_prefix:, ipv4_dst_prefix:, **)
      egress_match = {
        eth_type: ETH_TYPE_IPV4,
        ip_proto: ip_proto
      }.tap { |match|
        if !any_address?(ipv4_src_address, ipv4_src_prefix)
          match[:ipv4_dst] = ipv4_src_address
          match[:ipv4_dst_mask] = IPV4_BROADCAST << (32 - ipv4_src_prefix)
        end

        if !any_address?(ipv4_dst_address, ipv4_dst_prefix)
          match[:ipv4_src] = ipv4_dst_address
          match[:ipv4_src_mask] = IPV4_BROADCAST << (32 - ipv4_dst_prefix)
        end
      }

      ingress_match = {
        eth_type: ETH_TYPE_IPV4,
        ip_proto: ip_proto
      }.tap { |match|
        if !any_address?(ipv4_src_address, ipv4_src_prefix)
          match[:ipv4_src] = ipv4_src_address
          match[:ipv4_src_mask] = IPV4_BROADCAST << (32 - ipv4_src_prefix)
        end

        if !any_address?(ipv4_dst_address, ipv4_dst_prefix)
          match[:ipv4_dst] = ipv4_dst_address
          match[:ipv4_dst_mask] = IPV4_BROADCAST << (32 - ipv4_dst_prefix)
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
    
    def rule_for_arp(ipv4_src_address:, ipv4_dst_address:, ipv4_src_prefix:, ipv4_dst_prefix:, **)
      egress_match = {
        eth_type: ETH_TYPE_ARP,
      }.tap { |match|
        if !any_address?(ipv4_src_address, ipv4_src_prefix)
          match[:arp_tpa] = ipv4_src_address
          match[:arp_tpa_mask] = IPV4_BROADCAST << (32 - ipv4_src_prefix)
        end

        if !any_address?(ipv4_dst_address, ipv4_dst_prefix)
          match[:arp_spa] = ipv4_dst_address
          match[:arp_spa_mask] = IPV4_BROADCAST << (32 - ipv4_dst_prefix)
        end
      }

      ingress_match = {
        eth_type: ETH_TYPE_ARP,
      }.tap { |match|
        if !any_address?(ipv4_src_address, ipv4_src_prefix)
          match[:arp_spa] = ipv4_src_address
          match[:arp_spa_mask] = IPV4_BROADCAST << (32 - ipv4_src_prefix)
        end

        if !any_address?(ipv4_dst_address, ipv4_dst_prefix)
          match[:arp_tpa] = ipv4_dst_address
          match[:arp_tpa_mask] = IPV4_BROADCAST << (32 - ipv4_dst_prefix)
        end
      }

      return [egress_match, ingress_match]
    end

    def flows_for_static(flows, protocol, filter, action)
      rules(filter, protocol).tap { |egress_rule, ingress_rule|
        flow_base = {
          priority: priority_for_static(filter),
          match_interface: @interface_id
        }

        case action
        when 'conn'
          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_EGRESS_FILTER,
                                               match: egress_rule,
                                               actions: { output: Vnet::Openflow::Controller::OFPP_CONTROLLER }))
        when 'pass'
          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_INGRESS_FILTER,
                                               goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                                               match: ingress_rule))

          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_EGRESS_FILTER,
                                               goto_table: TABLE_INTERFACE_EGRESS_VALIDATE,
                                               match: egress_rule))
        when 'drop'
          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_INGRESS_FILTER,
                                               goto_table: nil,
                                               match: ingress_rule))

          flows << flow_create(flow_base.merge(table: TABLE_INTERFACE_EGRESS_FILTER,
                                               goto_table: nil,
                                               match: egress_rule))
        end
      }
    end

    def match_from_message(message)
      return if !message.ipv4?

      egress_match = {
        eth_type: ETH_TYPE_IPV4,
        ipv4_src: message.ipv4_src,
        ipv4_dst: message.ipv4_dst
      }
      ingress_match = {
        eth_type: ETH_TYPE_IPV4,
        ipv4_src: message.ipv4_dst,
        ipv4_dst: message.ipv4_src
      }

      case
      when message.tcp?
        egress_match.merge!(ip_proto: IPV4_PROTOCOL_TCP,
                            tcp_src: message.tcp_src,
                            tcp_dst: message.tcp_dst)
        ingress_match.merge!(ip_proto: IPV4_PROTOCOL_TCP,
                             tcp_src: message.tcp_dst,
                             tcp_dst: message.tcp_src)
      when message.udp?
        egress_match.merge!(ip_proto: IPV4_PROTOCOL_UDP,
                            udp_src: message.udp_src,
                            udp_dst: message.udp_dst)
        ingress_match.merge!(ip_proto: IPV4_PROTOCOL_UDP,
                             udp_src: message.udp_dst,
                             udp_dst: message.udp_src)
      when message.icmpv4?
        egress_match.merge!(ip_proto: IPV4_PROTOCOL_ICMP)
        ingress_match.merge!(ip_proto: IPV4_PROTOCOL_ICMP)
      when message.arpv4?
        egress_match.merge!(ip_proto: IPV4_PROTOCOL_ARP)
        ingress_match.merge!(ip_proto: IPV4_PROTOCOL_ARP)
      else
        # Do nothing.
      end

      return egress_match, ingress_match
    end

  end
end
