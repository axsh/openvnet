# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  # Simulated interfaces does all packet handling using the OpenFlow
  # controller.

  class Simulated < Base
    include Vnet::Openflow::ArpLookup

    def initialize(params)
      super

      arp_lookup_initialize(interface_id: @id,
                            lookup_cookie: self.cookie_for_tag(TAG_ARP_LOOKUP),
                            reply_cookie: self.cookie_for_tag(TAG_ARP_REPLY))
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      flows = []

      flows_for_ipv4(flows, mac_info, ipv4_info)
      arp_lookup_ipv4_flows(flows, mac_info, ipv4_info)

      @dp_info.add_flows(flows)
    end

    def install
      flows = []

      flows_for_base(flows)
      arp_lookup_base_flows(flows)

      @dp_info.add_flows(flows)
    end

    def packet_in(message)
      # info "simulated packet in: #{message.inspect}"

      tag = (message.cookie & COOKIE_TAG_MASK) >> COOKIE_TAG_SHIFT

      # process only OPTIONAL_TYPE_TAG
      return unless tag & OPTIONAL_TYPE_MASK == OPTIONAL_TYPE_TAG

      value = (message.cookie >> OPTIONAL_VALUE_SHIFT) & OPTIONAL_VALUE_MASK

      case value
      when TAG_ARP_REQUEST_INTERFACE
        info log_format('simulated arp reply', "arp_tpa:#{message.arp_tpa}")

        mac_info, ipv4_info = get_ipv4_address(any_md: message.match.metadata,
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

      when TAG_ARP_LOOKUP
        # info "simulated arp lookup: #{message.ipv4_dst}"

        arp_lookup_lookup_packet_in(message)

      when TAG_ARP_REPLY
        # info "simulated arp reply: #{message.ipv4_dst}"

        arp_lookup_reply_packet_in(message)

      when TAG_ICMP_REQUEST
        mac_info, ipv4_info = get_ipv4_address(any_md: message.match.metadata,
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

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} interfaces/simulated: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_base(flows)
      flows << flow_create(:catch_interface_simulated,
                           match: {
                             :eth_type => 0x0806,
                             :arp_op => 1,
                           },
                           interface_id: @id,
                           cookie: self.cookie_for_tag(TAG_ARP_REQUEST_INTERFACE))
      flows << flow_create(:catch_interface_simulated,
                           match: {
                             :eth_type => 0x0800,
                             :ip_proto => 0x01,
                             :icmpv4_type => Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REQUEST,
                           },
                           interface_id: @id,
                           cookie: self.cookie_for_tag(TAG_ICMP_REQUEST))
    end

    # TODO: Separate the mac-only flows and add those when
    # add_mac_address is called.
    def flows_for_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(:network_dst,
                           priority: 80,
                           match: {
                             :eth_type => 0x0800,
                             :eth_dst => mac_info[:mac_address],
                             :ipv4_dst => ipv4_info[:ipv4_address]
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           write_metadata: {
                             :interface => @id
                           },
                           cookie: cookie,
                           goto_table: TABLE_OUTPUT_INTERFACE)
      flows << flow_create(:network_dst,
                           priority: 80,
                           match: {
                             :eth_type => 0x0806,
                             :eth_dst => mac_info[:mac_address],
                             :arp_tpa => ipv4_info[:ipv4_address]
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           write_metadata: {
                             :interface => @id
                           },
                           cookie: cookie,
                           goto_table: TABLE_OUTPUT_INTERFACE)
      flows << flow_create(:catch_flood_simulated,
                           match: {
                             :eth_type => 0x0806,
                             :arp_op => 1,
                             :arp_tha => MAC_ZERO,
                             :arp_tpa => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie)
    end

  end

end
