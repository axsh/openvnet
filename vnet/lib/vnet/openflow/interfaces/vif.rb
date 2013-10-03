# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Vif < Base

    TAG_IPV4_ADDRESS = 0x1

    def initialize(params)
      super
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      @datapath.network_manager.update_interface(event: :insert,
                                                 id: ipv4_info[:network_id],
                                                 interface_id: @id,
                                                 mode: :vif,
                                                 port_number: @port_number)

      return if @port_number.nil?

      @datapath.network_manager.add_port(id: ipv4_info[:network_id],
                                         port_number: @port_number,
                                         port_mode: :vif,
                                         ip_address: ipv4_info[:ipv4_address])

      flows = []
      flows_for_ipv4(flows, mac_info, ipv4_info)

      @datapath.add_flows(flows)
    end

    def remove_ipv4_address(params)
      debug "interfaces: removing ipv4 flows..."

      mac_info, ipv4_info = super

      return unless ipv4_info

      @datapath.network_manager.update_interface(event: :remove,
                                                 id: ipv4_info[:network_id],
                                                 interface_id: @id,
                                                 mode: :vif,
                                                 port_number: @port_number)

      del_cookie_for_ip_lease(ipv4_info[:ip_lease_id])
    end

    def install
      return if @port_number.nil?

      flows = []
      flows_for_base(flows)

      @datapath.add_flows(flows)
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
        flows = []
        flows_for_base(flows)

        # @mac_addresses.each...

        # add_port...

        # @datapath.network_manager.update_interface(event: :update,
        #                                            id: ipv4_info[:network_id],
        #                                            interface_id: @id,
        #                                            port_number: @port_number)

        if !@mac_addresses.empty?
          info log_format("MAC/IP addresses loaded before port number is set is not yet supported, no flows created.")
        end

        @datapath.add_flows(flows)
      end
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} interfaces/vif: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_base(flows)
      flows << flow_create(:classifier,
                           priority: 2,
                           match: {
                             :in_port => @port_number,
                           },
                           write_metadata: {
                             :vif => nil,
                             :local => nil,
                           },
                           goto_table: TABLE_VIF_PORTS)
    end

    def flows_for_mac(flows, mac_info)
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

    def flows_for_ipv4(flows, mac_info, ipv4_info)
      #
      # Classifier
      #
      flows << flow_create(:vif_ports_match,
                           match: {
                             :in_port => @port_number,
                             :eth_src => mac_info[:mac_address],
                           },
                           write_metadata: {
                             :network => ipv4_info[:network_id],
                           },
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))
      flows << flow_create(:host_ports,
                           priority: 30,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           write_metadata: {
                             :network => ipv4_info[:network_id],
                           },
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]),
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
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))
      flows << flow_create(:network_src_arp_drop,
                           match: {
                             :eth_type => 0x0806,
                             :arp_spa => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))

      # Note that we should consider adding a table for handling
      # segments flows prior to the network classifier table.
      flows << flow_create(:network_src_arp_drop,
                           match: {
                             :eth_type => 0x0806,
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))
      flows << flow_create(:network_src_arp_drop,
                           match: {
                             :eth_type => 0x0806,
                             :arp_sha => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))

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
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]),
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
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]),
                           goto_table: TABLE_ROUTER_CLASSIFIER)
      flows << flow_create(:network_src,
                           priority: 44,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_src => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))
      flows << flow_create(:network_src,
                           priority: 44,
                           match: {
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))

      flows << flow_create(:network_src,
                           priority: 35,
                           match: {
                             :in_port => @port_number,
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]),
                           goto_table: TABLE_ROUTER_CLASSIFIER)
      flows << flow_create(:network_src,
                           priority: 34,
                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))

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
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))

      flows << flow_create(:network_dst,
                           priority: 60,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           actions: {
                             :output => @port_number
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: self.cookie_for_ip_lease(ipv4_info[:ip_lease_id]))

    end

  end

end
