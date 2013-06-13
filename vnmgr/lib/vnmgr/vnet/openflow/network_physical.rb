# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class NetworkPhysical < Network

    def flow_options
      @flow_options ||= {:cookie => (self.network_number << COOKIE_NETWORK_SHIFT)}
    end

    def install
      flows = []
      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {
                             :eth_dst => Trema::Mac.new('ff:ff:ff:ff:ff:ff')
                           }, {},
                           flow_options.merge({ :metadata => OFPP_FLOOD,
                                                :metadata_mask => METADATA_PORT_MASK,
                                                :goto_table => TABLE_PHYSICAL_SRC
                                              }))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 40, {
                             :eth_type => 0x0800,
                           }, {}, flow_options)

      self.datapath.add_flows(flows)
    end

    def update_flows
      flood_actions = ports.collect { |key,port| {:output => port.port_number} }

      flows = []
      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {
                             :metadata => OFPP_FLOOD,
                             :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
                           }, flood_actions, flow_options)

      eth_port_actions = self.datapath.switch.eth_ports.collect { |port| {:output => port.port_number} }
      eth_port_actions << {:output => OFPP_LOCAL}

      flows << Flow.create(TABLE_ARP_ROUTE, 0, {
                             :eth_type => 0x0806
                           }, eth_port_actions, flow_options)

      self.datapath.add_flows(flows)
    end

  end
  
end
