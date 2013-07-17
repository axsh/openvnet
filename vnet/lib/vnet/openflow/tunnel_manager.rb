# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TunnelManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers
    
    def initialize(dp)
      @datapath = dp
      @tunnels = []
    end

    def create_all_tunnels
      debug "creating tunnel ports"

      mydp = Vnet::ModelWrappers::Datapath.first(:dpid => "0x%016x" % @datapath.datapath_id)

      raise "Datapath not found: #{'0x%016x' % @datapath.datapath_id}" unless mydp

      @tunnels = Vnet::ModelWrappers::Datapath.batch.on_other_segment(mydp).all.commit.map do |other_dp|
        tunnel = Vnet::ModelWrappers::Tunnel.create(:src_datapath_id => mydp.id, :dst_datapath_id => other_dp.id)
        @datapath.add_tunnel(tunnel.uuid, IPAddr.new(other_dp.ipv4_address, Socket::AF_INET).to_s)
        tunnel.to_hash.tap do |t|
          t[:dst_dpid] = other_dp.dpid
          t[:datapath_networks] = []
        end
      end
    end

    def insert(dpn_map, should_update = false)
      datapath_network = {
        :id => dpn_map.id,
        :uuid => dpn_map.datapath.uuid,
        :dpid => dpn_map.datapath.dpid,
        :display_name => dpn_map.datapath.display_name,
        :ipv4_address => dpn_map.datapath.ipv4_address,
        :datapath_id => dpn_map.datapath.datapath_id,
        :broadcast_mac_addr => Trema::Mac.new(dpn_map.broadcast_mac_addr),
        :network_id => dpn_map.network_id,
      }

      tunnel = @tunnels.find{ |t| t[:dst_dpid] == datapath_network[:dpid] }
      tunnel[:datapath_networks] << datapath_network

      cookie = datapath_network[:id] | (COOKIE_PREFIX_DP_NETWORKS << COOKIE_PREFIX_SHIFT)

      flows = []
      flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                             :eth_dst => datapath_network[:broadcast_mac_addr]
                           }, {}, {
                             :cookie => cookie
                           })
      
      @datapath.add_flows(flows)

      update_network_id(datapath_network[:network_id]) if should_update
    end

    def prepare_network(network_map, dp_map)
      update_networks = false

      MW::DatapathNetwork.batch.on_other_segment(dp_map).where(:network_id => network_map.id).all.commit(:fill => :datapath).each { |dp|
        self.insert(dp, false)

        # Only add non-existing ones...
        update_networks = true
      }

      update_network_id(network_map.id) if update_networks
    end

    private

    def update_network_id(network_id)
      collection_id = find_collection_id(network_id)

      cookie = network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)
      md = md_create(:collection => collection_id)

      flows = []
      flows << Flow.create(TABLE_METADATA_TUNNEL_IDS, 1,
                           md_create({ :virtual_network => network_id,
                                       :flood => nil
                                     }), {
                             :tunnel_id => network_id | TUNNEL_FLAG_MASK
                           }, md.merge({ :cookie => cookie,
                                         :goto_table => TABLE_METADATA_TUNNEL_PORTS
                                       }))
      
      @datapath.add_flows(flows)
    end

    def find_collection_id(network_id)
      # Currently only use the network id as the collection id.
      #
      # Later collections should be created as needed and shared
      # between network's when possible.
      update_collection_id(network_id)

      network_id
    end

    def update_collection_id(collection_id)
      # Rewrite this to store the tunnel port numbers in TunnelManager.

      tunnel_ports = @datapath.switch.tunnel_ports.select do |tunnel_port|
        tunnel = @tunnels.find{ |t| t[:uuid] == tunnel_port.port_name }
        unless tunnel
          warn "tunnel port: #{tunnel_port.port_name} is not registered in db"
          next
        end
        tunnel[:datapath_networks].any?{|dpn| dpn[:network_id] == collection_id}
      end

      md = md_create(:collection => collection_id)
      cookie = collection_id | (COOKIE_PREFIX_COLLECTION << COOKIE_PREFIX_SHIFT)

      flows = []
      flows << Flow.create(TABLE_METADATA_TUNNEL_PORTS, 1,
                           md, tunnel_ports.map { |tunnel_port|
                             {:output => tunnel_port.port_number}
                           }, {
                             :cookie => cookie
                           })

      @datapath.add_flows(flows)
    end

  end

end
