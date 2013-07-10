# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortHost
    include Constants

    def eth?
      true
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, {}, flow_options.merge({ :metadata => METADATA_FLAG_REMOTE,
                                                       :metadata_mask => METADATA_FLAG_REMOTE,
                                                       :goto_table => TABLE_HOST_PORTS
                                                     }))

      flows << Flow.create(TABLE_HOST_PORTS, 20, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806},
                           {}, flow_options.merge(:goto_table => TABLE_ARP_ANTISPOOF))
      flows << Flow.create(TABLE_HOST_PORTS, 10, {
                             :in_port => self.port_number
                           }, {}, flow_options.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))

      flows << Flow.create(TABLE_MAC_ROUTE, 0, {}, {
                             :output => self.port_number
                           }, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 1, metadata_np(0x0), {
                             :output => self.port_number
                           }, flow_options)

      flows << Flow.create(TABLE_PHYSICAL_DST, 25, {
                             :in_port => self.port_number
                           }, {}, flow_options.merge(metadata_p(OFPP_LOCAL)).merge(:goto_table => TABLE_PHYSICAL_SRC))
      flows << Flow.create(TABLE_PHYSICAL_DST, 20, {}, {}, fo_load_port(TABLE_PHYSICAL_SRC))

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
                           }, {}, flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))

      flows << Flow.create(TABLE_ARP_ANTISPOOF, 1, {
                             :eth_type => 0x0806,
                             :in_port => self.port_number
                           }, {}, flow_options.merge(:goto_table => TABLE_ARP_ROUTE))

      self.datapath.add_flows(flows)
      self.datapath.switch.network_manager.update_all_flows
      self.datapath.switch.ports.each { |key,port| port.update_eth_ports }
    end

  end

end
