# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortPhysical
    include Constants

    def flow_options
      @flow_options ||= {:cookie => self.port_number | (self.network_number << COOKIE_NETWORK_SHIFT)}
    end

    def install
      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 3, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806
                           }, {}, flow_options.merge(:goto_table => TABLE_ARP_ANTISPOOF))
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, {}, flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))
      flows << Flow.create(TABLE_HOST_PORTS, 10, {
                             :eth_src => self.hw_addr
                           }, {}, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {
                             :eth_dst => self.hw_addr
                           }, {}, flow_options_load_port(TABLE_PHYSICAL_SRC))

      # flows << Flow.create(TABLE_PHYSICAL_SRC, 5, {:eth_src => self.hw_addr}, {}, flow_options)
      # flows << Flow.create(TABLE_PHYSICAL_SRC, 5, {:eth_type => 0x0800, :ipv4_src => IPAddr.new('192.168.60.200')}, {}, flow_options)
      # flows << Flow.create(TABLE_PHYSICAL_SRC, 4, {:in_port => self.port_number}, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))

      if self.ipv4_addr
        flows << Flow.create(TABLE_PHYSICAL_SRC, 45, {
                               :in_port => self.port_number,
                               :eth_src => self.hw_addr,
                               :eth_type => 0x0800,
                               :ipv4_src => self.ipv4_addr
                             }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))
        flows << Flow.create(TABLE_PHYSICAL_SRC, 44, {
                               :eth_type => 0x0800,
                               :ipv4_src => self.ipv4_addr
                             }, {}, flow_options)
      end

      flows << Flow.create(TABLE_PHYSICAL_SRC, 20, {
                             :in_port => self.port_number,
                             :eth_src => self.hw_addr,
                           }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 10, {
                             :in_port => self.port_number,
                             :eth_src => self.hw_addr
                           }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))

      #
      # ARP routing table
      #
      flows << Flow.create(TABLE_ARP_ANTISPOOF, 3, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806,
                             :eth_src => self.hw_addr,
                             :arp_sha => self.hw_addr,
                             :arp_spa => self.ipv4_addr
                           }, {}, flow_options.merge(:goto_table => TABLE_ARP_ROUTE))
      flows << Flow.create(TABLE_ARP_ANTISPOOF, 2, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806,
                             :eth_src => self.hw_addr,
                           }, {}, flow_options)
      flows << Flow.create(TABLE_ARP_ANTISPOOF, 2, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806,
                             :arp_sha => self.hw_addr,
                           }, {}, flow_options)
      flows << Flow.create(TABLE_ARP_ANTISPOOF, 2, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806,
                             :arp_spa => self.ipv4_addr
                           }, {}, flow_options)

      if self.ipv4_addr
        flows << Flow.create(TABLE_ARP_ROUTE, 1, {
                               :eth_type => 0x0806,
                               :arp_tpa => self.ipv4_addr
                             }, {
                               :output => self.port_number
                             }, flow_options)
      end

      flows << Flow.create(TABLE_MAC_ROUTE, 1, {
                             :eth_dst => self.hw_addr
                           }, {:output => self.port_number}, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {
                             :metadata => self.port_number,
                             :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
                           }, {
                             :output => self.port_number
                           }, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
