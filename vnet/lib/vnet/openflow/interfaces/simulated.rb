# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  # Simulated interfaces does all packet handling using the OpenFlow
  # controller.

  class Simulated < IfBase
    include Vnet::Openflow::ArpLookup

    def initialize(params)
      super

      arp_lookup_initialize(interface_id: @id,
                            lookup_cookie: self.cookie_for_tag(TAG_ARP_LOOKUP),
                            reply_cookie: self.cookie_for_tag(TAG_ARP_REPLY))
    end

    def add_mac_address(params)
      mac_info = super

      flows = []
      flows_for_mac(flows, mac_info)
      flows_for_interface_mac(flows, mac_info)

      if @enable_routing
        flows_for_router_ingress_mac(flows, mac_info)
        flows_for_router_egress_mac(flows, mac_info)
      end

      @dp_info.add_flows(flows)
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      flows = []

      flows_for_ipv4(flows, mac_info, ipv4_info)
      flows_for_interface_ipv4(flows, mac_info, ipv4_info)
      flows_for_mac2mac_ipv4(flows, mac_info, ipv4_info)

      if @enable_routing
        flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
        flows_for_router_ingress_mac2mac_ipv4(flows, mac_info, ipv4_info)
        flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
      end

      arp_lookup_ipv4_flows(flows, mac_info, ipv4_info)

      @mac_addresses.values.any? do |m|
        m[:ipv4_addresses].any? do |i|
          i[:ip_lease_id] != ipv4_info[:ip_lease_id] &&
            i[:network_id] == ipv4_info[:network_id]
        end
      end || @dp_info.service_manager.async.update_item(event: :add_network,
                                                        interface_id: @id,
                                                        network_id: ipv4_info[:network_id],
                                                        cookie_id: ipv4_info[:cookie_id])

      @dp_info.add_flows(flows)
    end

    def remove_ipv4_address(params)
      mac_info, ipv4_info = super
      return unless ipv4_info

      @mac_addresses.values.any? do |m|
        m[:ipv4_addresses].any? do |i|
          i[:ip_lease_id] != ipv4_info[:ip_lease_id] &&
            i[:network_id] == ipv4_info[:network_id]
        end
      end || @dp_info.service_manager.async.update_item(event: :remove_network,
                                                        interface_id: @id,
                                                        network_id: ipv4_info[:network_id])
    end

    #
    # Events:
    #

    def install
      flows = []

      flows_for_disabled_filtering(flows) unless @ingress_filtering_enabled
      flows_for_base(flows)
      arp_lookup_base_flows(flows)

      if @enable_routing && !@enable_route_translation
        flows_for_route_translation(flows)
      end

      @dp_info.add_flows(flows)
    end

    def uninstall
      @dp_info.service_manager.update_item(event: :remove_all_networks,
                                           interface_id: @id)
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

    def del_flows_for_active_datapath(ipv4_addresses)
      ipv4_addresses.each do |ipv4_address|
        next unless has_network?(ipv4_address[:network_id])

        options = {
          table_id: TABLE_ARP_LOOKUP,
          cookie: cookie_for_tag(TAG_ARP_REPLY),
          cookie_mask: COOKIE_PREFIX_MASK | COOKIE_ID_MASK | COOKIE_TAG_MASK,
          eth_type: 0x0800,
          ipv4_dst: ipv4_address[:ipv4_address],
        }.merge(md_create(network: ipv4_address[:network_id]))

        @dp_info.del_flows(options)
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
      flows << flow_create(:default,
                           table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 30,
                           match: {
                             :eth_type => 0x0806,
                             :arp_op => 1,
                           },
                           match_interface: @id,
                           actions: {
                             :output => Vnet::Openflow::Controller::OFPP_CONTROLLER
                           },
                           cookie: self.cookie_for_tag(TAG_ARP_REQUEST_INTERFACE))
      flows << flow_create(:default,
                           table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 30,
                           match: {
                             :eth_type => 0x0800,
                             :ip_proto => 0x01,
                             :icmpv4_type => Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REQUEST,
                           },
                           match_interface: @id,
                           actions: {
                             :output => Vnet::Openflow::Controller::OFPP_CONTROLLER
                           },
                           cookie: self.cookie_for_tag(TAG_ICMP_REQUEST))
    end

    def flows_for_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      #
      # Classifiers:
      #
      flows << flow_create(:default,
                           table: TABLE_CONTROLLER_PORT,
                           goto_table: TABLE_INTERFACE_EGRESS_CLASSIFIER,
                           priority: 30,

                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           write_interface: @id,
                           cookie: cookie)
    end

    def flows_for_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      flows << flow_create(:default,
                           table: TABLE_FLOOD_SIMULATED,
                           goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 30,
                           match: {
                             :eth_type => 0x0806,
                             :arp_op => 1,
                             :arp_tha => MAC_ZERO,
                             :arp_tpa => ipv4_info[:ipv4_address],
                           },
                           match_network: ipv4_info[:network_id],
                           write_interface: @id,
                           cookie: cookie)
    end

  end

end
