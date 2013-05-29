# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class NetworkVirtual < Network

    def flow_options
      @flow_options ||= {:cookie => (self.network_number << COOKIE_NETWORK_SHIFT)}
    end

    def install
      flows = []

      flows << Flow.create(TABLE_VIRTUAL_SRC, 4, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
                             :metadata_mask => METADATA_NETWORK_MASK | METADATA_TUNNEL_MASK,
                           }, {}, flow_options)
      # 6-2	 0	 0	 => arp,reg1=0x7
      # actions=learn(table=7,idle_timeout=36000,priority=1,reg1=0x7,reg2=0,
      # NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[],output:NXM_NX_REG2[]),resubmit(,7)
      flows << Flow.create(TABLE_VIRTUAL_SRC, 2, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
                             :metadata_mask => METADATA_NETWORK_MASK,
                           }, {}, flow_options)

      #
      # Network service related ICMP/ARP flows. (Example)
      #
      flows << Flow.create(TABLE_VIRTUAL_DST, 7, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
                             :metadata_mask => METADATA_NETWORK_MASK,
                             :eth_type => 0x0806,
                             :ipv4_dst => IPAddr.new('192.168.60.2'),
                           }, {
                             :output => Controller::OFPP_CONTROLLER
                           }, flow_options)
      flows << Flow.create(TABLE_VIRTUAL_DST, 7, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
                             :metadata_mask => METADATA_NETWORK_MASK,
                             :eth_type => 0x0801,
                             :ipv4_dst => IPAddr.new('192.168.60.2'),
                           }, {
                             :output => Controller::OFPP_CONTROLLER
                           }, flow_options)
      
      flows << Flow.create(TABLE_VIRTUAL_DST, 7, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
                             :metadata_mask => METADATA_NETWORK_MASK,
                             :eth_type => 0x0811,
                             :eth_dst => Trema::Mac.new('08:00:27:10:ED:B5'),
                             :ipv4_dst => IPAddr.new('192.168.60.2'),
                             :udp_src => 68,
                             :udp_dst => 67,
                           }, {
                             :output => Controller::OFPP_CONTROLLER
                           }, flow_options)
      flows << Flow.create(TABLE_VIRTUAL_DST, 7, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
                             :metadata_mask => METADATA_NETWORK_MASK,
                             :eth_type => 0x0811,
                             :eth_dst => Trema::Mac.new('ff:ff:ff:ff:ff:ff'),
                             :ipv4_dst => IPAddr.new('255.255.255.255'),
                             :udp_src => 68,
                             :udp_dst => 67,
                           }, {
                             :output => Controller::OFPP_CONTROLLER
                           }, flow_options)

      # 7-1	 0	 0	 => reg1=0x7,reg2=0x0,dl_dst=ff:ff:ff:ff:ff:ff actions=output:3
      # 7-0	 0	 0	 => reg1=0x7,dl_dst=ff:ff:ff:ff:ff:ff actions=output:3

      flows << Flow.create(TABLE_VIRTUAL_DST, 4, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
                             :metadata_mask => METADATA_NETWORK_MASK | METADATA_TUNNEL_MASK,
                             :eth_dst => Trema::Mac.new('ff:ff:ff:ff:ff:ff')
                           }, {},
                           flow_options.merge({ :metadata => (self.network_number << METADATA_NETWORK_SHIFT) | OFPP_FLOOD,
                                                :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK),
                                                :goto_table => TABLE_METADATA_ROUTE
                                              }))

      self.datapath.add_flows(flows)
    end

    def update_flows
      flood_actions = ports.collect { |key,port| {:output => port.port_number} }

      flows = []
      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT) | OFPP_FLOOD,
                             :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
                           }, flood_actions, flow_options)

      self.datapath.add_flows(flows)
    end

  end
  
end
