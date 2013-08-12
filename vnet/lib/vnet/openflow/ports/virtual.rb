# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Virtual
    include Vnet::Openflow::FlowHelpers

    def port_type
      :virtual
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []

      network_md = flow_options.merge(md_network(:network))

      if @network_id
        classifier_md = flow_options.merge(md_network(:network, {
                                                        :local => nil,
                                                        :vif => nil
                                                      }))

        flows << Flow.create(TABLE_CLASSIFIER, 2, {
                               :in_port => self.port_number
                             }, nil,
                             classifier_md.merge(:goto_table => TABLE_NETWORK_SRC_CLASSIFIER))
        flows << Flow.create(TABLE_HOST_PORTS, 30, {
                               :eth_dst => self.hw_addr,
                             }, nil,
                             network_md.merge(:goto_table => TABLE_NETWORK_SRC_CLASSIFIER))
        flows << Flow.create(TABLE_VIRTUAL_DST, 60,
                             network_md.merge(:eth_dst => self.hw_addr), {
                               :output => self.port_number
                             }, flow_options)
      end

      flows << Flow.create(TABLE_VIRTUAL_SRC, 40, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800,
                             :eth_src => @hw_addr,
                             :ipv4_src => IPV4_ZERO,
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_CLASSIFIER))

      self.datapath.add_flows(flows)
    end

  end

end
