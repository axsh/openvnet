# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortLocal
    include FlowHelpers

    attr_reader :bridge_hw

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      set_local_md = flow_options.merge(md_create(:local => nil))

      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 3, {
                             :in_port => OFPP_LOCAL,
                             :eth_type => 0x0806
                           }, {}, set_local_md.merge(:goto_table => TABLE_ARP_ANTISPOOF))
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => OFPP_LOCAL
                           }, {}, set_local_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))

      flows << Flow.create(TABLE_METADATA_ROUTE, 1,
                           md_port(:network => 0), {
                             :output => self.port_number
                           }, flow_options)

      # Some flows depend on only local being able to send packets
      # with the local mac and ip address, so drop those.
      flows << Flow.create(TABLE_PHYSICAL_SRC, 60, {
                             :in_port => OFPP_LOCAL
                           }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))

      #
      # ARP routing table
      #
      flows << Flow.create(TABLE_ARP_ANTISPOOF, 1, {
                             :in_port => OFPP_LOCAL,
                             :eth_type => 0x0806
                           }, {}, flow_options.merge(:goto_table => TABLE_ARP_ROUTE))

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
                           }, {}, flow_options.merge(md_port).merge!(:goto_table => TABLE_PHYSICAL_SRC))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 50, {
                             :eth_src => self.bridge_hw
                           }, {}, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
