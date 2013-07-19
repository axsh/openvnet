# -*- coding: utf-8 -*-

module Vnet::Openflow

  module PortHost
    include FlowHelpers

    def eth?
      true
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      set_remote_md = flow_options.merge(md_create(:remote => nil))
      port_local_md = flow_options.merge(md_create(:physical_port => OFPP_LOCAL))
      port_self_md  = flow_options.merge(md_create(:physical_port => self.port_number))
      network_md    = flow_options.merge(md_network(:physical_network))

      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, {
                           }, set_remote_md.merge(:goto_table => TABLE_HOST_PORTS))

      flows << Flow.create(TABLE_HOST_PORTS, 20, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806}, {
                           }, flow_options.merge(:goto_table => TABLE_ARP_ANTISPOOF))
      flows << Flow.create(TABLE_HOST_PORTS, 10, {
                             :in_port => self.port_number
                           }, {
                           }, network_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))

      flows << Flow.create(TABLE_MAC_ROUTE, 0, {}, {
                             :output => self.port_number
                           }, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 1,
                           port_self_md, {
                             :output => self.port_number
                           }, flow_options)

      flows << Flow.create(TABLE_PHYSICAL_DST, 25, {
                             :in_port => self.port_number
                           }, {},
                           port_local_md.merge(:goto_table => TABLE_PHYSICAL_SRC))
      flows << Flow.create(TABLE_PHYSICAL_DST, 20, {}, {},
                           port_self_md.merge(:goto_table => TABLE_PHYSICAL_SRC))

      flows << Flow.create(TABLE_PHYSICAL_SRC, 41, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800
                           }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 21, {
                             :in_port => self.port_number
                           }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))

      if self.ipv4_addr
        flows << Flow.create(TABLE_PHYSICAL_SRC, 44, {
                               :in_port => self.port_number,
                               :eth_type => 0x0800,
                               :ipv4_src => self.ipv4_addr
                             }, {}, flow_options)
      end

      flows << Flow.create(TABLE_VIRTUAL_SRC, 30, {
                             :in_port => self.port_number
                           }, {}, flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))

      flows << Flow.create(TABLE_ARP_ANTISPOOF, 1, {
                             :eth_type => 0x0806,
                             :in_port => self.port_number
                           }, {}, flow_options.merge(:goto_table => TABLE_ARP_ROUTE))

      self.datapath.add_flows(flows)
      self.datapath.switch.network_manager.update_all_flows
    end

  end

end
