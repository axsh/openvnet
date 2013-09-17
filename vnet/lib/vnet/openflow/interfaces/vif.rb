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
      # Classifier
      #
      flows << flow_create(:classifier,
                           priority: 2,
                           match: {
                             :in_port => @port_number,
                           },
                           write_metadata: {
                             :network => ipv4_info[:network_id],
                             :vif => nil,
                             :local => nil,
                           },
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER)
      flows << flow_create(:host_ports,
                           priority: 30,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           write_metadata: {
                             :network => ipv4_info[:network_id],
                           },
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER)

      #
      # ARP anti-spoof
      #
      flows << flow_create(:network_src_arp_match,
                           match: {
                             :in_port => @port_number,
                             :eth_type => 0x0806,
                             :eth_src => mac_info[:mac_address],
                             :arp_spa => ipv4_info[:ipv4_address],
                             :arp_sha => mac_info[:mac_address]
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type])
      flows << flow_create(:network_src_arp_drop,
                           match: {
                             :eth_type => 0x0806,
                             :arp_spa => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type])

      # Note that we should consider adding a table for handling
      # segments flows prior to the network classifier table.
      flows << flow_create(:network_src_arp_drop,
                           match: {
                             :eth_type => 0x0806,
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type])
      flows << flow_create(:network_src_arp_drop,
                           match: {
                             :eth_type => 0x0806,
                             :arp_sha => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type])

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
                           goto_table: TABLE_ROUTER_CLASSIFIER)
      flows << flow_create(:network_src,
                           priority: 45,
                           match: {
                             :in_port => @port_number,
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                             :ipv4_src => IPV4_ZERO,
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           goto_table: TABLE_ROUTER_CLASSIFIER)
      flows << flow_create(:network_src,
                           priority: 44,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_src => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type])
      flows << flow_create(:network_src,
                           priority: 44,
                           match: {
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type])

      flows << flow_create(:network_src,
                           priority: 35,
                           match: {
                             :in_port => @port_number,
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           goto_table: TABLE_ROUTER_CLASSIFIER)
      flows << flow_create(:network_src,
                           priority: 34,
                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type])

      flows << flow_create(:router_dst_match,
                           priority: 40,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_dst => ipv4_info[:ipv4_address],
                           },
                           actions: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id])

      flows << flow_create(:network_dst,
                           priority: 60,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           actions: {
                             :output => @port_number
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type])

    end

  end

end
