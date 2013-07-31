# -*- coding: utf-8 -*-

module Vnet::Openflow

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
      flood_md = flow_options.merge(md_network(:network, :flood => nil))
      any_network_md = flow_options.merge(md_network(:network))

      flows = []
      flows << Flow.create(TABLE_TUNNEL_NETWORK_IDS, 30, {
                             :tunnel_id => self.network_id | TUNNEL_FLAG_MASK
                           }, {},
                           any_network_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))
      flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 40,
                           md_network(:virtual_network), {},
                           flow_options.merge(:goto_table => TABLE_VIRTUAL_SRC))
      flows << Flow.create(TABLE_VIRTUAL_DST, 40,
                           md_network(:network, :local => nil).merge!(:eth_dst => MAC_BROADCAST), {},
                           flood_md.merge!(:goto_table => TABLE_METADATA_ROUTE))
      flows << Flow.create(TABLE_VIRTUAL_DST, 30,
                           md_network(:network, :remote => nil).merge!(:eth_dst => MAC_BROADCAST), {},
                           flood_md.merge!(:goto_table => TABLE_METADATA_LOCAL))

      if self.broadcast_mac_addr
        flows << Flow.create(TABLE_HOST_PORTS, 30, {
                               :eth_dst => self.broadcast_mac_addr
                             }, {
                               :eth_dst => MAC_BROADCAST
                             }, any_network_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))
        flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                               :eth_dst => self.broadcast_mac_addr
                             }, {}, flow_options)
        flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                               :eth_src => self.broadcast_mac_addr
                             }, {}, flow_options)
      end

      self.datapath.add_flows(flows)

      ovs_flows = []
      ovs_flows << create_ovs_flow_learn_arp(83, "tun_id=0,")
      ovs_flows << create_ovs_flow_learn_arp(81, "", "load:NXM_NX_TUN_ID\\[\\]\\-\\>NXM_NX_TUN_ID\\[\\],")
      ovs_flows.each { |flow| self.datapath.add_ovs_flow(flow) }
    end

    def update_flows
      flows = []
      flood_actions = self.ports.collect { |key,port| {:output => port.port_number} }

      flows << Flow.create(TABLE_METADATA_LOCAL, 1,
                           md_network(:network, :flood => nil),
                           flood_actions, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 1,
                           md_network(:network, :flood => nil),
                           flood_actions, flow_options.merge(:goto_table => TABLE_METADATA_SEGMENT))

      self.datapath.add_flows(flows)
    end

    def create_ovs_flow_learn_arp(priority, match_options = "", learn_options = "")
      #
      # Work around the current limitations of trema / openflow 1.3 using ovs-ofctl directly.
      #
      match_md = md_network(:virtual_network, :remote => nil)
      learn_md = md_network(:virtual_network, {:local => nil, :vif => nil})

      flow_learn_arp = "table=#{TABLE_VIRTUAL_SRC},priority=#{priority},cookie=0x%x,arp,metadata=0x%x/0x%x,#{match_options}actions=" %
        [@cookie, match_md[:metadata], match_md[:metadata_mask]]
      flow_learn_arp << "learn\\(table=%d,cookie=0x%x,idle_timeout=36000,priority=35,metadata:0x%x,NXM_OF_ETH_DST\\[\\]=NXM_OF_ETH_SRC\\[\\]," %
        [TABLE_VIRTUAL_DST, @cookie, learn_md[:metadata]]
        
      flow_learn_arp << learn_options

      flow_learn_arp << "output:NXM_OF_IN_PORT\\[\\]\\),goto_table:%d" % TABLE_ROUTER_ENTRY
      flow_learn_arp
    end
  end
  
end
