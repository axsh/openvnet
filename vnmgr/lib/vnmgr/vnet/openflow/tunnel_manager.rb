# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class TunnelManager
    include Constants
    
    attr_reader :datapath
    attr_reader :peer_datapaths

    def initialize(dp)
      @datapath = dp
      @peer_datapaths = []
    end

    def insert(dpn_map, should_update)
      datapath = {
        :uuid => dpn_map.datapath_map[:uuid],
        :dpid => dpn_map.datapath_map[:dpid],
        :display_name => dpn_map.datapath_map[:display_name],
        :ipv4_address => dpn_map.datapath_map[:ipv4_address],
        :datapath_id => dpn_map.datapath_map[:datapath_id],
        :broadcast_mac_addr => Trema::Mac.new(dpn_map.broadcast_mac_addr),
      }

      # p "Adding datapath to list of networks on the same subnet: network:#{self.uuid} datapath:#{datapath.inspect}"

      @peer_datapaths << datapath

      @datapath.add_flow(Flow.create(Constants::TABLE_VIRTUAL_SRC, 90, {
                                       :eth_dst => datapath[:broadcast_mac_addr]
                                     }, {}, {
                                       #TODO: Use proper cookie.
                                       :cookie => 0x1
                                     }))

      update_all_networks if should_update
    end

    def update_all_networks
      @datapath.switch.network_manager.networks.each { |nw_id,network|
        self.update_virtual_network(network) if network.class == NetworkVirtual
      }
    end

    def update_network(network)
      self.update_virtual_network(network) if network.class == NetworkVirtual
    end

    def update_virtual_network(network)
    
      datapath_id = @datapath.datapath_id
      @datapath.switch.gre_ports.each do |gre_port|
      
        flow_flood = "table=#{TABLE_METADATA_TUNNEL},priority=1,cookie=0x%x,metadata=0x%x/0x%x,actions=" %
          [(network.network_number << COOKIE_NETWORK_SHIFT),
           ((network.network_number << METADATA_NETWORK_SHIFT) | OFPP_FLOOD),
           (METADATA_PORT_MASK | METADATA_NETWORK_MASK)
          ]

        @peer_datapaths.each { |datapath|
          flow_flood << ",mod_dl_dst=#{datapath[:broadcast_mac_addr]},output=#{gre_port.port_number}"
        }

        @datapath.ovs_ofctl.add_ovs_flow(flow_flood)
      end
    end

  end

end    
