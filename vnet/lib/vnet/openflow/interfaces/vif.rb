# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  class Vif < Base

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      @dp_info.network_manager.update_interface(event: :insert,
                                                 id: ipv4_info[:network_id],
                                                 interface_id: @id,
                                                 mode: :vif,
                                                 port_number: @port_number)

      flows = []
      flows_for_ipv4(flows, mac_info, ipv4_info)

      @dp_info.add_flows(flows)
    end

    def remove_ipv4_address(params)
      debug "interfaces: removing ipv4 flows..."

      mac_info, ipv4_info = super

      return unless ipv4_info

      @dp_info.network_manager.update_interface(event: :remove,
                                                 id: ipv4_info[:network_id],
                                                 interface_id: @id,
                                                 mode: :vif,
                                                 port_number: @port_number)
    end

    def install
      flows = []
      flows_for_base(flows)

      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} interfaces/vif: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_base(flows)
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
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      #
      # Classifier
      #
      flows << flow_create(:vif_ports_match,
                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           match_metadata: {
                             :interface => @id
                           },
                           write_metadata: {
                             :network => ipv4_info[:network_id],
                           },
                           cookie: cookie)
      flows << flow_create(:host_ports,
                           priority: 30,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           write_metadata: {
                             :network => ipv4_info[:network_id],
                           },
                           cookie: cookie,
                           goto_table: TABLE_NETWORK_SRC_CLASSIFIER)

      #
      # ARP anti-spoof
      #
      flows << flow_create(:network_src_arp_match,
                           match: {
                             :eth_type => 0x0806,
                             :eth_src => mac_info[:mac_address],
                             :arp_spa => ipv4_info[:ipv4_address],
                             :arp_sha => mac_info[:mac_address]
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie)
      flows << flow_create(:network_src_arp_drop,
                           match: {
                             :eth_type => 0x0806,
                             :arp_spa => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie)

      # Note that we should consider adding a table for handling
      # segments flows prior to the network classifier table.
      flows << flow_create(:network_src_arp_drop,
                           match: {
                             :eth_type => 0x0806,
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie)
      flows << flow_create(:network_src_arp_drop,
                           match: {
                             :eth_type => 0x0806,
                             :arp_sha => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie)

      #
      # IPv4 
      #
      flows << flow_create(:network_src_ipv4_match,
                           match: {
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                             :ipv4_src => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie,
                           goto_table: TABLE_ROUTER_CLASSIFIER)
      flows << flow_create(:network_src_ipv4_match,
                           match: {
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                             :ipv4_src => IPV4_ZERO,
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie,
                           goto_table: TABLE_ROUTER_CLASSIFIER)
      flows << flow_create(:network_src,
                           priority: 44,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_src => ipv4_info[:ipv4_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie)
      flows << flow_create(:network_src,
                           priority: 44,
                           match: {
                             :eth_type => 0x0800,
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie)

      flows << flow_create(:network_src_mac_match,
                           priority: 35,
                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie,
                           goto_table: TABLE_ROUTER_CLASSIFIER)

      flows << flow_create(:network_src,
                           priority: 34,
                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie)

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
                           cookie: cookie)

      flows << flow_create(:network_dst,
                           priority: 60,
                           match: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           write_metadata: {
                             :interface => @id,
                           },
                           network_id: ipv4_info[:network_id],
                           network_type: ipv4_info[:network_type],
                           cookie: cookie,
                           goto_table: TABLE_INTERFACE_VIF)

    end

  end

end
