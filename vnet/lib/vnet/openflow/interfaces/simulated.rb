# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Simulated < Base

    TAG_ARP_REQUEST  = 0x1
    TAG_ICMP_REQUEST = 0x2

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      install_arp_request(mac_info, ipv4_info)
      install_icmp_request(mac_info, ipv4_info)
    end

    def packet_in(message)
      info "simulated packet in: #{message.inspect}"

      case (message.cookie & COOKIE_TAG_MASK) >> COOKIE_TAG_SHIFT
      when TAG_ARP_REQUEST
        mac_info, ipv4_info = get_ipv4_address(network_md: message.match.metadata,
                                               ipv4_address: message.arp_tpa)
        return if mac_info.nil? || ipv4_info.nil?

        packet_arp_out({ :out_port => message.in_port,
                         :in_port => OFPP_CONTROLLER,
                         :eth_src => mac_info[:mac_address],
                         :eth_dst => message.eth_src,
                         :op_code => Racket::L3::ARP::ARPOP_REPLY,
                         :sha => mac_info[:mac_address],
                         :spa => ipv4_info[:ipv4_address],
                         :tha => message.eth_src,
                         :tpa => message.arp_spa,
                       })

      when TAG_ICMP_REQUEST
        mac_info, ipv4_info = get_ipv4_address(network_md: message.match.metadata,
                                               ipv4_address: message.ipv4_dst)
        return if mac_info.nil? || ipv4_info.nil?

        raw_in = icmpv4_in(message)

        case message.icmpv4_type
        when Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REQUEST
          icmpv4_out({ :out_port => message.in_port,

                       :eth_src => mac_info[:mac_address],
                       :eth_dst => message.eth_src,
                       :ipv4_src => ipv4_info[:ipv4_address],
                       :ipv4_dst => message.ipv4_src,

                       :icmpv4_type => Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REPLY,
                       :icmpv4_id => raw_in.l4.id,
                       :icmpv4_sequence => raw_in.l4.sequence,

                       :payload => raw_in.l4.payload
                     })
        end
        
      end

    end

    #
    # Internal methods:
    #

    private

    def install_arp_request(mac_info, ipv4_info)
      flows = []
      flows << flow_create(:catch_network_dst,
                           match: {
                             :eth_dst => MAC_BROADCAST,
                             :eth_type => 0x0806,
                             :arp_op => 1,
                             :arp_tha => MAC_ZERO,
                             :arp_tpa => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie(TAG_ARP_REQUEST))
      flows << flow_create(:catch_network_dst,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                             :eth_type => 0x0806,
                             :arp_op => 1,
                             :arp_tpa => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie(TAG_ARP_REQUEST))

      @datapath.add_flows(flows)
    end

    def install_icmp_request(mac_info, ipv4_info)
      flows = []
      flows << flow_create(:catch_network_dst,
                           match: {
                             :eth_type => 0x0800,
                             :eth_dst => mac_info[:mac_address],
                             :ip_proto => 0x01,
                             :ipv4_dst => ipv4_info[:ipv4_address]
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie(TAG_ICMP_REQUEST))

      @datapath.add_flows(flows)
    end

  end

end

