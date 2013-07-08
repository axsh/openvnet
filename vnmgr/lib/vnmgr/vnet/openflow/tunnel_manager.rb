# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class TunnelManager
    include Constants
    include Celluloid::Logger
    
    attr_reader :datapath
    attr_reader :tunnels

    def initialize(dp)
      @datapath = dp
      @tunnels = []
    end

    def cookie
      @cookie ||= datapath.switch.cookie_manager.acquire(:tunnel)
    end

    def create_all_tunnels
      debug "creating tunnel ports"

      mydp = Vnmgr::ModelWrappers::Datapath.first(:dpid => "0x%016x" % self.datapath.datapath_id)
      raise "Datapath not found: #{'0x%016x' % self.datapath.datapath_id}" unless mydp
      @tunnels = Vnmgr::ModelWrappers::Datapath.batch.on_other_segment(mydp).all.commit.map do |other_dp|
        tunnel = Vnmgr::ModelWrappers::Tunnel.create(:src_datapath_id => mydp.id, :dst_datapath_id => other_dp.id)
        self.datapath.add_tunnel(tunnel.uuid, IPAddr.new(other_dp.ipv4_address, Socket::AF_INET).to_s)
        tunnel.to_hash.tap do |t|
          t[:dst_dpid] = other_dp.dpid
          t[:datapath_networks] = []
        end
      end
    end

    def insert(dpn_map, should_update = false)
      datapath_network = {
        :uuid => dpn_map.datapath_map[:uuid],
        :dpid => dpn_map.datapath_map[:dpid],
        :display_name => dpn_map.datapath_map[:display_name],
        :ipv4_address => dpn_map.datapath_map[:ipv4_address],
        :datapath_id => dpn_map.datapath_map[:datapath_id],
        :broadcast_mac_addr => Trema::Mac.new(dpn_map.broadcast_mac_addr),
        :network_number => dpn_map.network_id,
        :cookie => self.cookie,
      }

      tunnel = self.tunnels.find{ |t| t[:dst_dpid] == datapath_network[:dpid] }
      tunnel[:datapath_networks] << datapath_network

      @datapath.add_flow(Flow.create(Constants::TABLE_VIRTUAL_SRC, 90, {
                                       :eth_dst => datapath_network[:broadcast_mac_addr]
                                     }, {}, {
                                       :cookie => self.cookie
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
      flows = []

      # tunnels whose peer datapath has the network
      tunnel_ports = @datapath.switch.tunnel_ports.select do |tunnel_port|
        tunnel = self.tunnels.find{ |t| t[:uuid] == tunnel_port.port_name }
        unless tunnel
          warn "tunnel port: #{tunnel_port.port_name} is not registered in db"
          next
        end
        tunnel[:datapath_networks].any?{|dpn| dpn[:network_number] == network.network_number}
      end

      # flood flow
      flows << Flow.create(TABLE_METADATA_TUNNEL, 1,
        { :metadata => (network.network_number << METADATA_NETWORK_SHIFT) | OFPP_FLOOD,
          :metadata_mask => METADATA_PORT_MASK | METADATA_NETWORK_MASK },
        tunnel_ports.map { |tunnel_port|
          { :eth_dst => Trema::Mac.new('ff:ff:ff:ff:ff:ff'),
            :tunnel_id => network.network_number | TUNNEL_FLAG,
            :output => tunnel_port.port_number}
        },
        { :cookie => self.cookie })

      # catch flow
      tunnel_ports.each do |tunnel_port|
        flows << Flow.create(TABLE_VIRTUAL_SRC, 30,
          { :in_port => tunnel_port.port_number,
            :tunnel_id => network.network_number,
            :tunnel_id_mask => TUNNEL_NETWORK_MASK },
          nil,
          { :goto_table => TABLE_VIRTUAL_DST, :cookie => self.cookie })
      end

      @datapath.add_flows(flows)
    end
  end

end
