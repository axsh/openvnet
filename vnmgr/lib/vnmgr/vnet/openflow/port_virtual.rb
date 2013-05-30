# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortVirtual
    include Constants

    def flow_options
      @flow_options ||= {:cookie => self.port_number | (self.network_number << COOKIE_NETWORK_SHIFT)}
    end

    def install
      flows = []

      flows << Flow.create(TABLE_CLASSIFIER,   2, {
                             :in_port => self.port_number
                           }, {}, flow_options_load_network(TABLE_VIRTUAL_SRC))

      #
      # ARP Anti-Spoof:
      #
      flows << Flow.create(TABLE_VIRTUAL_SRC, 9, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806,
                             :eth_src => self.hw_addr,
                             :arp_spa => self.ipv4_addr,
                             :arp_sha => self.hw_addr
                           }, {}, flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))
      flows << Flow.create(TABLE_VIRTUAL_SRC, 8, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806
                           }, {}, flow_options)

      #
      # IPv4 source validation:
      #
      flows << Flow.create(TABLE_VIRTUAL_SRC, 6, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800,
                             :eth_src => self.hw_addr,
                             :ipv4_src => self.ipv4_addr,
                           }, {}, flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))
      flows << Flow.create(TABLE_VIRTUAL_SRC, 6, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800,
                             :eth_src => self.hw_addr,
                             :ipv4_src => IPAddr.new('0.0.0.0'),
                           }, {}, flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))

      #
      # Destination routing:
      #
      flows << Flow.create(TABLE_VIRTUAL_DST, 6, {
                             :metadata => self.network_number << METADATA_NETWORK_SHIFT,
                             :metadata_mask => METADATA_NETWORK_SHIFT,
                             :eth_dst => self.hw_addr,
                           }, {
                             :output => self.port_number,
                           }, flow_options)

      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT) | self.port_number,
                             :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
                           }, {
                             :output => self.port_number
                           }, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
