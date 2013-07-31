# -*- coding: utf-8 -*-

module Vnet::Openflow

  module PortLocal
    include FlowHelpers

    attr_reader :bridge_hw

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      network_md = flow_options.merge(md_network(:physical_network, :local => nil))

      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => OFPP_LOCAL
                           }, nil,
                           network_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))

      # Some flows depend on only local being able to send packets
      # with the local mac and ip address, so drop those.
      flows << Flow.create(TABLE_PHYSICAL_SRC, 31, {
                             :in_port => OFPP_LOCAL
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 41, {
                             :in_port => OFPP_LOCAL,
                             :eth_type => 0x0800
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 41, {
                             :in_port => OFPP_LOCAL,
                             :eth_type => 0x0806
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))

      self.datapath.add_flows(flows)
    end

    def install_with_hw(bridge_hw)
      @bridge_hw = bridge_hw

      flows = []
      # flows << Flow.create(TABLE_PHYSICAL_SRC, 35, {
      #                        :eth_src => self.bridge_hw
      #                      }, nil,
      #                      flow_options)
      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {
                             :eth_dst => self.bridge_hw
                           }, {
                             :output => OFPP_LOCAL
                           }, flow_options)
      flows << Flow.create(TABLE_MAC_ROUTE, 1, {
                             :eth_dst => self.bridge_hw
                           }, {
                             :output => OFPP_LOCAL
                           }, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
