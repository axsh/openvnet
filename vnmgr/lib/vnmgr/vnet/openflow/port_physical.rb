# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortPhysical
    include Constants

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 3, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806
                           }, {}, flow_options.merge({ :metadata => METADATA_FLAG_LOCAL,
                                                       :metadata_mask => METADATA_FLAG_LOCAL,
                                                       :goto_table => TABLE_ARP_ANTISPOOF
                                                     }))
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, {}, flow_options.merge({ :metadata => METADATA_FLAG_LOCAL,
                                                       :metadata_mask => METADATA_FLAG_LOCAL,
                                                       :goto_table => TABLE_NETWORK_CLASSIFIER
                                                     }))
      flows << Flow.create(TABLE_HOST_PORTS, 10, {
                             :eth_src => self.hw_addr
                           }, {}, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {
                             :eth_dst => self.hw_addr
                           }, {}, fo_load_port(TABLE_PHYSICAL_SRC))

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

      flows << Flow.create(TABLE_PHYSICAL_SRC, 25, {
                             :in_port => self.port_number,
                             :eth_src => self.hw_addr,
                           }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 24, {
                             :eth_src => self.hw_addr
                           }, {}, flow_options)

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
        flows << Flow.create(TABLE_ARP_ROUTE, 2, {
                               :eth_type => 0x0806,
                               :arp_tpa => self.ipv4_addr
                             }, {
                               :output => self.port_number
                             }, flow_options)
      end

      flows << Flow.create(TABLE_MAC_ROUTE, 1, {
                             :eth_dst => self.hw_addr
                           }, {:output => self.port_number}, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 1, metadata_np(0x0), {
                             :output => self.port_number
                           }, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
