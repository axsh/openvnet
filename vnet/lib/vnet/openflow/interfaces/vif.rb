# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Vif < Base

    attr_reader :port_number

    def initialize(params)
      super
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      return if @port_number.nil?

      flows = []

      install_ipv4(flows, mac_info, ipv4_info)

      @datapath.add_flows(flows)
    end

    def install
      # flows = []

      # flows << flow_create(:catch_interface_simulated,
      #                      match: {
      #                        :eth_type => 0x0806,
      #                        :arp_op => 1,
      #                      },
      #                      interface_id: @id,
      #                      cookie: self.cookie(TAG_ARP_REQUEST_INTERFACE))
      # flows << flow_create(:catch_interface_simulated,
      #                      match: {
      #                        :eth_type => 0x0800,
      #                        :ip_proto => 0x01,
      #                        :icmpv4_type => Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REQUEST,
      #                      },
      #                      interface_id: @id,
      #                      cookie: self.cookie(TAG_ICMP_REQUEST))

      # @datapath.add_flows(flows)
    end

    def update_port_number(new_number)
      return if @port_number == new_number

      # Event barrier for port number based events.
      old_number = @port_number
      @port_number = nil

      if old_number
        # remove flows
      end

      @port_number = new_number

      if new_number
        # flows = []

        # install_base
        # @mac_addresses.each...

        if !@mac_addresses.empty?
          info log_format("MAC/IP addresses loaded before port number is set is not yet supported, no flows created.")
        end

        # @datapath.add_flows(flows)
      end
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} interfaces/vif: #{message}" + (values ? " (#{values})" : '')
    end

    def install_mac(flows, mac_info)
      # flows << flow_create(:segment_src,
      #                      priority: 85,
      #                      match: {
      #                        :eth_type => 0x0806,
      #                        :eth_src => mac_info[:mac_address],
      #                      },
      #                      network_id: ipv4_info[:network_id],
      #                      network_type: ipv4_info[:network_type],
      #                      cookie: self.cookie)
      # flows << flow_create(:segment_src,
      #                      priority: 85,
      #                      match: {
      #                        :eth_type => 0x0806,
      #                        :arp_sha => mac_info[:mac_address],
      #                      },
      #                      network_id: ipv4_info[:network_id],
      #                      network_type: ipv4_info[:network_type],
      #                      cookie: self.cookie)
    end

    def install_ipv4(flows, mac_info, ipv4_info)
      #
      # ARP anti-spoof
      #
      flows << flow_create(:network_src,
                           priority: 86,
                           match: {
                             :in_port => @port_number,
                             :eth_type => 0x0806,
                             :eth_src => mac_info[:mac_address],
                             :arp_spa => ipv4_info[:ipv4_address],
                             :arp_sha => mac_info[:mac_address]
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           goto_table: TABLE_ROUTER_CLASSIFIER,
                           cookie: self.cookie)
      flows << flow_create(:network_src,
                           priority: 85,
                           match: {
                             :eth_type => 0x0806,
                             :arp_spa => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie)

      # Note that we should consider adding a table for handling
      # segments flows prior to the network classifier table.
      flows << flow_create(:network_src,
                           priority: 85,
                           match: {
                             :eth_type => 0x0806,
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie)
      flows << flow_create(:network_src,
                           priority: 85,
                           match: {
                             :eth_type => 0x0806,
                             :arp_sha => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie)

      #
      # IPv4 
      #
      flows << flow_create(:network_src,
                           priority: 45,
                           match: {
                             :in_port => @port_number,
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                             :ipv4_src => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           goto_table: TABLE_ROUTER_CLASSIFIER,
                           cookie: self.cookie)
      flows << flow_create(:network_src,
                           priority: 44,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_src => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie)
      flows << flow_create(:router_dst_match,
                           priority: 40,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_dst => ipv4_info[:ipv4_address],
                           },
                           actions: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           cookie: self.cookie)
    end

  end

end
