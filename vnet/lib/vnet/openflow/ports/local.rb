# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Local
    include Vnet::Openflow::FlowHelpers

    def port_type
      :local
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []

      if @network_id
        fo_network_md = flow_options.merge(md_network(:physical_network, :local => nil))

        flows << Flow.create(TABLE_CLASSIFIER, 2, {
                               :in_port => OFPP_LOCAL
                             }, nil,
                             fo_network_md.merge(:goto_table => TABLE_NETWORK_SRC_CLASSIFIER))
      end

      # Some flows depend on only local being able to send packets
      # with the local mac and ip address, so drop those.
      flows << Flow.create(TABLE_PHYSICAL_SRC, 31, {
                             :in_port => OFPP_LOCAL
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_CLASSIFIER))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 41, {
                             :in_port => OFPP_LOCAL,
                             :eth_type => 0x0800
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_CLASSIFIER))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 41, {
                             :in_port => OFPP_LOCAL,
                             :eth_type => 0x0806
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_CLASSIFIER))
      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {
                             :eth_dst => @hw_addr
                           }, {
                             :output => OFPP_LOCAL
                           }, flow_options)
      flows << Flow.create(TABLE_MAC_ROUTE, 1, {
                             :eth_dst => @hw_addr
                           }, {
                             :output => OFPP_LOCAL
                           }, flow_options)

      if @network_id && @ipv4_addr
        network_md = md_network(:physical_network)

        flows << Flow.create(TABLE_ROUTER_DST, 40,
                             network_md.merge({ :eth_type => 0x0800,
                                                :ipv4_dst => @ipv4_addr
                                              }), {
                               :eth_dst => @hw_addr
                             },
                             flow_options.merge(:goto_table => TABLE_NETWORK_DST_CLASSIFIER))
      end

      self.datapath.add_flows(flows)
    end

  end

end
