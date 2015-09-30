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
      "filter_id:#{sf[:static_id]} ipv4_address:#{sf[:ipv4_address]} port_number:#{sf[:port_number]}"
    end
    
    def install

      return if @interface_id.nil?

      flows = []
      @statics.each { |id, filter|
        
        debug log_format('installing translation for ' + pretty_static(filter))
        
        flows_for_ingress_filtering(flows, filter)
        flows_for_egress_filtering(flows, filter)
      }

      @dp_info.add_flows(flows)

    end


    def added_static(static_id, ipv4_address, port_number, protocol)

      filter = {
        :static_id => static_id,
        :ipv4_address => ipv4_address,
        :port_number => port_number,
        :protocol => protocol
      }
      
      @statics[static_id] = filter

      return if @installed == false

      flows = []         
      flows_for_ingress_filtering(flows, filter) 
      flows_for_egress_filtering(flows, filter)

    end


    def removed_static(static_id)
    end

    #
    # Internal methods
    #

    private

    def match_actions_for_ingress(filter)
      case filter[:protocol]
      when 'tcp' then
        [{ eth_type: ETH_TYPE_IPV4,
           ipv4_src: filter[:ipv4_address],
           ip_proto: IPV4_PROTOCOL_TCP,
           tcp_dst: filter[:port_number]
        }]
      when 'udp' then
         [{ eth_type: ETH_TYPE_IPV4,
           ipv4_src: filter[:ipv4_address],
           ip_proto: IPV4_PROTOCOL_UDP,
           udp_dst: filter[:port_number]
          }]
      when 'icmp' then
        [{ eth_type: ETH_TYPE_IPV4,
          ipv4_src: filter[:ipv4_address],
          ip_proto: IPV4_PROTOCOL_ICMP
         }]
      end
    end

    def match_actions_for_egress(filter)
      case filter[:protocol]
      when "tcp" then
        [{ eth_type: ETH_TYPE_IPV4,
           ipv4_dst: filter[:ipv4_address],
           ip_proto: IPV4_PROTOCOL_TCP,
           tcp_dst: filter[:port_number]
         }]
      when "udp" then
         [{ eth_type: ETH_TYPE_IPV4,
           ipv4_dst: filter[:ipv4_address],
           ip_proto: IPV4_PROTOCOL_UDP,
           udp_dst: filter[:port_number]
          }]
      when "icmp" then
        [{ eth_type: ETH_TYPE_IPV4,
          ipv4_dst: filter[:ipv4_address],
          ip_proto: IPV4_PROTOCOL_ICMP
         }]
      when "arp" then
        [{ eth_type: ETH_TYPE_ARP }]
      end
    end

    def check_zero_value(match, filter)
        if filter[:port_number] == 0
          match.delete(:tcp_dst)
          match.delete(:udp_dst)
        end

        if filter[:ipv4_address] <= 0
          match.delete(:ipv4_src)
          match.delete(:ipv4_dst)
        end
        return match
    end

    def flows_for_ingress_filtering(flows = [], filter)

      match_actions_for_ingress(filter).each { |match|
        if @ingress_passthrough
          flows << flow_create(
            table: TABLE_INTERFACE_INGRESS_FILTER,
            goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
            priority: 10,
            match_interface: @interface_id,
            match: check_zero_value(match, filter),
          )
        else
          flows << flow_create(
            table: TABLE_INTERFACE_INGRESS_FILTER,
            priority: 50,
            match: check_zero_value(match, filter),
            match_interface: @interface_id
          )
        end
      }
    end

    def flows_for_egress_filtering(flows = [], filter)

      match_actions_for_egress(filter).each { |match|
        if @egress_passthrough
          flows << flow_create(
            table: TABLE_INTERFACE_EGRESS_FILTER,
            goto_table: TABLE_INTERFACE_EGRESS_VALIDATE,
            priority: 10,
            match_interface: @interface_id,
            match: check_zero_value(match, filter)
          )
        else
          flows << flow_create(
            table: TABLE_INTERFACE_EGRESS_FILTER,
            priority: 50,
            match_interface: @interface_id,
            match: check_zero_value(match, filter)
          )
        end
      }
    end
  end
end
