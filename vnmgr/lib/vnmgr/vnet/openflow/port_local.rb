# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortLocal
    include Constants

    attr_reader :bridge_hw

    def flow_options
      @flow_options ||= {:cookie => self.port_number | 0x0}
    end

    def install
      flows = []

      flows << Flow.create(TABLE_CLASSIFIER, 3, {
                             :in_port => OFPP_LOCAL,
                             :eth_type => 0x0806
                           }, {}, flow_options.merge({ :metadata => METADATA_FLAG_LOCAL,
                                                       :metadata_mask => METADATA_FLAG_LOCAL,
                                                       :goto_table => TABLE_ARP_ANTISPOOF
                                                     }))
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => OFPP_LOCAL
                           }, {}, flow_options.merge({ :metadata => METADATA_FLAG_LOCAL,
                                                       :metadata_mask => METADATA_FLAG_LOCAL,
                                                       :goto_table => TABLE_PHYSICAL_DST
                                                     }))

      flows << Flow.create(TABLE_METADATA_ROUTE, 0, metadata_np(0x0), {
                             :output => self.port_number
                           }, flow_options)

      # Some flows depend on only local being able to send packets
      # with the local mac and ip address, so drop those.
      flows << Flow.create(TABLE_PHYSICAL_SRC, 60, {
                             :in_port => OFPP_LOCAL
                           }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))
      # flows << Flow.create(TABLE_PHYSICAL_SRC, 5, {
      #                        :eth_type => 0x0800,
      #                        :ipv4_src => IPAddr.new('192.168.60.101')
      #                      }, {}, flow_options)

      #
      # ARP routing table
      #
      flows << Flow.create(TABLE_ARP_ANTISPOOF, 1, {
                             :in_port => OFPP_LOCAL,
                             :eth_type => 0x0806
                           }, {}, flow_options.merge(:goto_table => TABLE_ARP_ROUTE))
      # flows << Flow.create(TABLE_ARP_ROUTE, 1, {
      #                        :eth_type => 0x0806,
      #                        :arp_tpa => IPAddr.new('192.168.60.101')
      #                      }, {:output => OFPP_LOCAL}, flow_options)

      self.datapath.add_flows(flows)
    end

    def install_with_hw(bridge_hw)
      @bridge_hw = bridge_hw

      flows = []
      
      flows << Flow.create(TABLE_MAC_ROUTE, 1, {
                             :eth_dst => self.bridge_hw
                           }, {
                             :output => OFPP_LOCAL
                           }, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {
                             :eth_dst => self.bridge_hw
                           }, {}, flow_options_load_port(TABLE_PHYSICAL_SRC))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 50, {
                             :eth_src => self.bridge_hw
                           }, {}, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
