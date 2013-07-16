# -*- coding: utf-8 -*-

module Vnet::Openflow

  class NetworkPhysical < Network

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []
      flows << Flow.create(TABLE_PHYSICAL_DST, 30, {
                             :eth_dst => MAC_BROADCAST
                           }, {},
                           flow_options.merge(md_create(:flood => nil)).merge(:goto_table => TABLE_PHYSICAL_SRC))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 40, {
                             :eth_type => 0x0800,
                           }, {}, flow_options)

      self.datapath.add_flows(flows)
    end

    def update_flows
      flood_actions = ports.collect { |key,port| {:output => port.port_number} }

      flows = []
      flows << Flow.create(TABLE_METADATA_ROUTE, 1,
                           md_create(:network => 0, :flood => nil),
                           flood_actions, flow_options)

      eth_port_actions = self.datapath.switch.eth_ports.collect { |port| {:output => port.port_number} }
      eth_port_actions << {:output => OFPP_LOCAL}

      flows << Flow.create(TABLE_ARP_ROUTE, 1, {
                             :eth_type => 0x0806
                           }, eth_port_actions, flow_options)

      self.datapath.add_flows(flows)
    end

  end
  
end
