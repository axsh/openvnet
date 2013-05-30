# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortHost
    include Constants

    def is_eth_port
      true
    end

    def flow_options
      @flow_options ||= {:cookie => self.port_number | (self.network_number << COOKIE_NETWORK_SHIFT)}
      # @flow_options ||= {:cookie => self.port_number | 0x0}
    end

    def install
      flows = []

      flows << Flow.create(TABLE_CLASSIFIER,     3, {:in_port => self.port_number, :eth_type => 0x0806}, {}, flow_options.merge(:goto_table => TABLE_ARP_ANTISPOOF))
      flows << Flow.create(TABLE_CLASSIFIER,     2, {:in_port => self.port_number}, {}, flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))

      flows << Flow.create(TABLE_MAC_ROUTE,      0, {}, {:output => self.port_number}, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {
                             :metadata => self.port_number,
                             :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
                           }, {
                             :output => self.port_number
                           }, flow_options)

      flows << Flow.create(TABLE_PHYSICAL_DST,   0, {}, {}, flow_options_load_port(TABLE_PHYSICAL_SRC))
      flows << Flow.create(TABLE_PHYSICAL_SRC,   4, {:in_port => self.port_number}, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))

      flows << Flow.create(TABLE_ARP_ANTISPOOF,  1, {:eth_type => 0x0806, :in_port => self.port_number}, {}, flow_options.merge(:goto_table => TABLE_ARP_ROUTE))
      flows << Flow.create(TABLE_ARP_ROUTE,      0, {:eth_type => 0x0806}, {:output => self.port_number}, flow_options)

      self.datapath.add_flows(flows)
      self.datapath.switch.network_manager.update_all_flows
      self.datapath.switch.ports.each { |key,port| port.update_eth_ports }
    end

  end

end
