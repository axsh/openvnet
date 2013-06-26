# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class NetworkVirtual < Network

    # metadata[ 0-31]: Port number; only set to non-zero when the
    #                  in_port is not a local port. This allows us to
    #                  differentiate between packets that are from
    #                  external sources and those that are from
    #                  internal interfaces.
    # metadata[32-48]: Network id;
    # metadata[48-64]: Tunnel id; preliminary.

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []

      if self.datapath_of_bridge
        flows << Flow.create(TABLE_VIRTUAL_SRC, 90, {
                               :eth_dst => self.datapath_of_bridge[:broadcast_mac_addr]
                             }, {}, flow_options)
      end

      flows << Flow.create(TABLE_VIRTUAL_DST, 40,
                           metadata_pn.merge!(:eth_dst => Trema::Mac.new('ff:ff:ff:ff:ff:ff')), {},
                           flow_options.merge(metadata_pn(OFPP_FLOOD).merge!(:goto_table => TABLE_METADATA_ROUTE)))
      flows << Flow.create(TABLE_VIRTUAL_DST, 30,
                           metadata_n.merge!(:eth_dst => Trema::Mac.new('ff:ff:ff:ff:ff:ff')), {},
                           flow_options.merge(metadata_pn(OFPP_FLOOD).merge!(:goto_table => TABLE_METADATA_LOCAL)))

      self.datapath.add_flows(flows)
    end

    def update_flows
      flows = []
      flood_actions = self.ports.collect { |key,port| {:output => port.port_number} }

      flows << Flow.create(TABLE_METADATA_LOCAL, 1, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT) | OFPP_FLOOD,
                             :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
                           }, flood_actions, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 1, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT) | OFPP_FLOOD,
                             :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
                           }, flood_actions, flow_options.merge(:goto_table => TABLE_METADATA_SEGMENT))

      self.datapath.add_flows(flows)

      #
      # Work around the current limitations of trema / openflow 1.3 using ovs-ofctl directly.
      #

      eth_port = self.datapath.switch.eth_ports.first

      if eth_port
        if self.datapath_of_bridge
          flow_catch = "table=#{TABLE_HOST_PORTS},priority=30,cookie=0x%x,in_port=#{eth_port.port_number},dl_dst=#{self.datapath_of_bridge[:broadcast_mac_addr]}," % @cookie
          flow_catch << "actions=mod_dl_dst:ff:ff:ff:ff:ff:ff,write_metadata:0x%x/0x%x,goto_table:6" % 
            [((self.network_number << METADATA_NETWORK_SHIFT) | eth_port.port_number),
             (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
            ]

          self.datapath.ovs_ofctl.add_ovs_flow(flow_catch)
        end

        flow_learn_arp = "table=#{TABLE_VIRTUAL_SRC},priority=81,cookie=0x%x,in_port=#{eth_port.port_number},arp,metadata=0x%x/0x%x,actions=" %
          [@cookie,
           ((self.network_number << METADATA_NETWORK_SHIFT) | eth_port.port_number),
           (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
          ]
        flow_learn_arp << "learn\\(table=7,idle_timeout=36000,priority=35,cookie=0x%x,metadata:0x%x,NXM_OF_ETH_DST\\[\\]=NXM_OF_ETH_SRC\\[\\],output:NXM_OF_IN_PORT\\[\\]\\),goto_table:7" %
          [@cookie, ((self.network_number << METADATA_NETWORK_SHIFT) | METADATA_FLAG_LOCAL)]
        self.datapath.ovs_ofctl.add_ovs_flow(flow_learn_arp)
      end
    end

  end
  
end
