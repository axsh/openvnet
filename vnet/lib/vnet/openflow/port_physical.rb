# -*- coding: utf-8 -*-

module Vnet::Openflow

  module PortPhysical
    include FlowHelpers

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      network_md = md_network(:physical_network)
      network_local_interface_md = md_network(:physical_network, {
                                          :local => nil,
                                          :interface => nil
                                        })
      fo_network_md = flow_options.merge(network_md)
      fo_classifier_md = flow_options.merge(network_local_interface_md)

      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, nil,
                           fo_classifier_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))
      flows << Flow.create(TABLE_HOST_PORTS, 10, {
                             :eth_src => self.hw_addr
                           }, nil,
                           flow_options)

      flows << Flow.create(TABLE_PHYSICAL_SRC, 45, {
                             :in_port => self.port_number,
                             :eth_src => self.hw_addr,
                             :eth_type => 0x0800,
                             :ipv4_src => IPV4_ZERO
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 44, {
                             :eth_type => 0x0800,
                             :eth_src => self.hw_addr
                           }, nil,
                           flow_options)

      if self.ipv4_addr
        flows << Flow.create(TABLE_PHYSICAL_SRC, 45, {
                               :in_port => self.port_number,
                               :eth_src => self.hw_addr,
                               :eth_type => 0x0800,
                               :ipv4_src => self.ipv4_addr
                             }, nil,
                             flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))
        flows << Flow.create(TABLE_PHYSICAL_SRC, 44, {
                               :eth_type => 0x0800,
                               :ipv4_src => self.ipv4_addr
                             }, nil,
                             flow_options)
        flows << Flow.create(TABLE_ROUTER_DST, 40,
                             network_md.merge({ :eth_type => 0x0800,
                                                :ipv4_dst => @ipv4_addr
                                              }), {
                               :eth_dst => @hw_addr
                             },
                             flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))
        flows << Flow.create(TABLE_ARP_LOOKUP, 30,
                             network_md.merge({ :eth_type => 0x0800,
                                                :ipv4_dst => @ipv4_addr
                                              }), {
                               :eth_dst => @hw_addr
                             },
                             flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))
      end

      flows << Flow.create(TABLE_PHYSICAL_SRC, 35, {
                             :in_port => self.port_number,
                             :eth_src => self.hw_addr,
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 34, {
                             :eth_src => self.hw_addr
                           }, nil,
                           flow_options)

      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {
                             :eth_dst => self.hw_addr
                           }, {
                             :output => self.port_number
                           }, flow_options)

      #
      # ARP routing table
      #
      if self.ipv4_addr
        flows << Flow.create(TABLE_PHYSICAL_SRC, 45, {
                               :in_port => self.port_number,
                               :eth_type => 0x0806,
                               :eth_src => self.hw_addr,
                               :arp_sha => self.hw_addr,
                               :arp_spa => self.ipv4_addr
                             }, nil,
                             flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))
        flows << Flow.create(TABLE_PHYSICAL_SRC, 44, {
                               :eth_type => 0x0806,
                               :arp_spa => self.ipv4_addr
                             }, nil,
                             flow_options)
      end

      flows << Flow.create(TABLE_PHYSICAL_SRC, 44, {
                             :eth_type => 0x0806,
                             :eth_src => self.hw_addr,
                           }, nil,
                           flow_options)
      flows << Flow.create(TABLE_PHYSICAL_SRC, 44, {
                             :eth_type => 0x0806,
                             :arp_sha => self.hw_addr,
                           }, nil,
                           flow_options)

      # if self.ipv4_addr
      #   flows << Flow.create(TABLE_ARP_ROUTE, 2, {
      #                          :eth_type => 0x0806,
      #                          :arp_tpa => self.ipv4_addr
      #                        }, {
      #                          :output => self.port_number
      #                        }, flow_options)
      # end

      self.datapath.add_flows(flows)
    end

  end

end
