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
      @flow_options ||= {:cookie => (self.network_number << COOKIE_NETWORK_SHIFT)}
    end

    def install
      flows = []

      # flows << Flow.create(TABLE_VIRTUAL_SRC, 4, {
      #                        :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
      #                        :metadata_mask => METADATA_NETWORK_MASK | METADATA_TUNNEL_MASK,
      #                      }, {}, flow_options)
      # flows << Flow.create(TABLE_VIRTUAL_SRC, 2, {
      #                        :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
      #                        :metadata_mask => METADATA_NETWORK_MASK | METADATA_PORT_MASK,
      #                      }, {}, flow_options)

      if self.datapath_of_bridge
        flows << Flow.create(TABLE_VIRTUAL_SRC, 90, {
                               :eth_dst => Trema::Mac.new(self.datapath_of_bridge[:broadcast_mac_addr])
                             }, {}, flow_options)
      end

      #
      # Network service related ICMP/ARP flows. (Example)
      #
      # flows << Flow.create(TABLE_VIRTUAL_DST, 7, {
      #                        :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
      #                        :metadata_mask => METADATA_NETWORK_MASK,
      #                        :eth_type => 0x0806,
      #                        :ipv4_dst => IPAddr.new('192.168.60.2'),
      #                      }, {
      #                        :output => Controller::OFPP_CONTROLLER
      #                      }, flow_options)
      # flows << Flow.create(TABLE_VIRTUAL_DST, 7, {
      #                        :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
      #                        :metadata_mask => METADATA_NETWORK_MASK,
      #                        :eth_type => 0x0801,
      #                        :ipv4_dst => IPAddr.new('192.168.60.2'),
      #                      }, {
      #                        :output => Controller::OFPP_CONTROLLER
      #                      }, flow_options)
      
      # flows << Flow.create(TABLE_VIRTUAL_DST, 7, {
      #                        :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
      #                        :metadata_mask => METADATA_NETWORK_MASK,
      #                        :eth_type => 0x0811,
      #                        :eth_dst => Trema::Mac.new('08:00:27:10:ED:B5'),
      #                        :ipv4_dst => IPAddr.new('192.168.60.2'),
      #                        :udp_src => 68,
      #                        :udp_dst => 67,
      #                      }, {
      #                        :output => Controller::OFPP_CONTROLLER
      #                      }, flow_options)
      # flows << Flow.create(TABLE_VIRTUAL_DST, 7, {
      #                        :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
      #                        :metadata_mask => METADATA_NETWORK_MASK,
      #                        :eth_type => 0x0811,
      #                        :eth_dst => Trema::Mac.new('ff:ff:ff:ff:ff:ff'),
      #                        :ipv4_dst => IPAddr.new('255.255.255.255'),
      #                        :udp_src => 68,
      #                        :udp_dst => 67,
      #                      }, {
      #                        :output => Controller::OFPP_CONTROLLER
      #                      }, flow_options)

      # 7-1	 0	 0	 => reg1=0x7,reg2=0x0,dl_dst=ff:ff:ff:ff:ff:ff actions=output:3
      # 7-0	 0	 0	 => reg1=0x7,dl_dst=ff:ff:ff:ff:ff:ff actions=output:3

      flows << Flow.create(TABLE_VIRTUAL_DST, 40, {
                             :metadata => (self.network_number << METADATA_NETWORK_SHIFT),
                             :metadata_mask => METADATA_NETWORK_MASK | METADATA_PORT_MASK,
                             :eth_dst => Trema::Mac.new('ff:ff:ff:ff:ff:ff')
                           }, {},
                           flow_options.merge({ :metadata => (self.network_number << METADATA_NETWORK_SHIFT) | OFPP_FLOOD,
                                                :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK),
                                                :goto_table => TABLE_METADATA_ROUTE
                                              }))

      self.datapath.add_flows(flows)
    end

    def update_flows
      # flood_actions = self.ports.collect { |key,port| {:output => port.port_number} }
      # output_eth_ports = self.datapath.switch.eth_ports

      # if output_eth_ports.first
      #   self.datapaths_on_subnet.each { |datapath|
      #     flood_actions << {
      #       :eth_dst => { :mac_address => Trema::Mac.new(datapath[:broadcast_mac_addr]) },
      #       :output => output_eth_ports.first.port_number,
      #     }
      #   }
      # end

      flows = []
      # flows << Flow.create(TABLE_METADATA_ROUTE, 0, {
      #                        :metadata => (self.network_number << METADATA_NETWORK_SHIFT) | OFPP_FLOOD,
      #                        :metadata_mask => (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
      #                      }, flood_actions, flow_options)

      self.datapaths_on_subnet.each { |datapath|
        flows << Flow.create(TABLE_VIRTUAL_SRC, 90, {
                               :eth_dst => Trema::Mac.new(datapath[:broadcast_mac_addr])
                             }, {}, flow_options)
      }

      self.datapath.add_flows(flows)

      #
      # Work around the current limitations of trema / openflow 1.3 using ovs-ofctl directly.
      #

      flow_flood = "table=15,priority=0,cookie=0x%x,metadata=0x%x/0x%x,actions=" %
        [(self.network_number << COOKIE_NETWORK_SHIFT),
         ((self.network_number << METADATA_NETWORK_SHIFT) | OFPP_FLOOD),
         (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
        ]

      self.ports.collect { |key,port| flow_flood << ",output=#{port.port_number}" }

      eth_port = self.datapath.switch.eth_ports.first

      if eth_port
        self.datapaths_on_subnet.each { |datapath|
          flow_flood << ",mod_dl_dst=#{datapath[:broadcast_mac_addr]},output=#{eth_port.port_number}"
        }

        if self.datapath_of_bridge
          flow_catch = "table=#{TABLE_HOST_PORTS},priority=30,cookie=0x%x,in_port=#{eth_port.port_number},dl_dst=#{self.datapath_of_bridge[:broadcast_mac_addr]}," % (self.network_number << COOKIE_NETWORK_SHIFT)
          flow_catch << "actions=mod_dl_dst:ff:ff:ff:ff:ff:ff,write_metadata:0x%x/0x%x,goto_table:6" % 
            [((self.network_number << METADATA_NETWORK_SHIFT) | eth_port.port_number),
             (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
            ]

          self.datapath.ovs_ofctl.add_ovs_flow(flow_catch)
        end

        flow_learn_arp = "table=#{TABLE_VIRTUAL_SRC},priority=81,cookie=0x%x,in_port=#{eth_port.port_number},arp,metadata=0x%x/0x%x,actions=" %
          [(self.network_number << COOKIE_NETWORK_SHIFT),
           ((self.network_number << METADATA_NETWORK_SHIFT) | eth_port.port_number),
           (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
          ]
        flow_learn_arp << "learn\\(table=7,idle_timeout=36000,priority=20,metadata:0x%x,NXM_OF_ETH_DST\\[\\]=NXM_OF_ETH_SRC\\[\\],output:NXM_OF_IN_PORT\\[\\]\\),goto_table:7" %
          ((self.network_number << METADATA_NETWORK_SHIFT) | 0x0)
        self.datapath.ovs_ofctl.add_ovs_flow(flow_learn_arp)
      end

      self.datapath.ovs_ofctl.add_ovs_flow(flow_flood)
    end

  end
  
end
