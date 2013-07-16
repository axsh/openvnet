# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class NetworkVirtual < Network
    
    # metadata[ 0-31]: Port number; only set to non-zero when the
    #                  in_port is not a local port. This allows us to
    #                  differentiate between packets that are from
    #                  external sources and those that are from
    #                  internal interfaces.
    # metadata[32-47]: Network id;
    # metadata[48-64]: Tunnel id; preliminary.

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []

      broadcast_mac_addr = self.datapath_of_bridge && self.datapath_of_bridge[:broadcast_mac_addr]

      if broadcast_mac_addr
        flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                               :eth_dst => broadcast_mac_addr
                             }, {}, flow_options)
        flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                               :eth_src => broadcast_mac_addr
                             }, {}, flow_options)
      end

      flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 40, md_network(:network), {},
                           flow_options.merge(:goto_table => TABLE_VIRTUAL_SRC))

      flows << Flow.create(TABLE_VIRTUAL_DST, 40,
                           md_network(:local_network).merge!(:eth_dst => MAC_BROADCAST), {},
                           flow_options.merge(md_network(:network, :flood => nil).merge!(:goto_table => TABLE_METADATA_ROUTE)))
      flows << Flow.create(TABLE_VIRTUAL_DST, 30,
                           md_network(:remote_network).merge!(:eth_dst => MAC_BROADCAST), {},
                           flow_options.merge(md_network(:network, :flood => nil).merge!(:goto_table => TABLE_METADATA_LOCAL)))

      self.datapath.add_flows(flows)
    end

    def update_flows
      flows = []
      ovs_flows = []
      flood_actions = self.ports.collect { |key,port| {:output => port.port_number} }

      flows << Flow.create(TABLE_METADATA_LOCAL, 1,
                           md_network(:network, :flood => nil),
                           flood_actions, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 1,
                           md_network(:network, :flood => nil),
                           flood_actions, flow_options.merge(:goto_table => TABLE_METADATA_SEGMENT))

      self.datapath.switch.eth_ports.each { |eth_port|
        if self.datapath_of_bridge
          set_md = flow_options.merge(md_network(:virtual_network, :port => eth_port.port_number))

          flows << Flow.create(TABLE_HOST_PORTS, 30, {
                                 :in_port => eth_port.port_number,
                                 :eth_dst => self.datapath_of_bridge[:broadcast_mac_addr]
                               }, {
                                 :eth_dst => MAC_BROADCAST
                               }, set_md.merge!(:goto_table => TABLE_NETWORK_CLASSIFIER))
        end
        ovs_flows << create_ovs_flow_learn_arp(eth_port)
      }

      self.datapath.switch.tunnel_ports.each do |tunnel_port|
        ovs_flows << create_ovs_flow_learn_arp(tunnel_port, "load:NXM_NX_TUN_ID\\[\\]\\-\\>NXM_NX_TUN_ID\\[\\]," % self.network_number)
      end

      self.datapath.add_flows(flows)
      ovs_flows.each { |flow| self.datapath.add_ovs_flow(flow) }
    end

    def create_ovs_flow_learn_arp(port, learn_options = "")
      #
      # Work around the current limitations of trema / openflow 1.3 using ovs-ofctl directly.
      #
      match_md = md_network(:remote_network)
      learn_md = md_network(:local_network)

      flow_learn_arp = "table=#{TABLE_VIRTUAL_SRC},priority=81,cookie=0x%x,in_port=#{port.port_number},arp,metadata=0x%x/0x%x,actions=" %
        [@cookie, match_md[:metadata], match_md[:metadata_mask]]
      flow_learn_arp << "learn\\(table=%d,cookie=0x%x,idle_timeout=36000,priority=35,metadata:0x%x,NXM_OF_ETH_DST\\[\\]=NXM_OF_ETH_SRC\\[\\]," %
        [TABLE_VIRTUAL_DST, @cookie, learn_md[:metadata]]
        
      flow_learn_arp << learn_options

      flow_learn_arp << "output:NXM_OF_IN_PORT\\[\\]\\),goto_table:%d" % TABLE_ROUTER_ENTRY
      flow_learn_arp
    end
  end
  
end
