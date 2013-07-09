# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class DcSegmentManager
    include Celluloid
    include Celluloid::Logger
    include Vnmgr::Constants::Openflow
    
    def initialize(dp)
      @datapath = dp
      @segment_datapaths = {}
    end

    def insert(dpn_map, should_update)
      datapath = {
        :uuid => dpn_map.datapath.uuid,
        :display_name => dpn_map.datapath.display_name,
        :ipv4_address => dpn_map.datapath.ipv4_address,
        :datapath_id => dpn_map.datapath.dpid,
        :broadcast_mac_addr => Trema::Mac.new(dpn_map.broadcast_mac_addr),
        :cookie => @datapath.switch.cookie_manager.acquire(:dc_segment)
      }

      if datapath[:cookie].nil?
        error "No more cookies available for DC segment flows."
        return
      end

      (@segment_datapaths[dpn_map.network_id] ||= []) << datapath

      actions = {:cookie => datapath[:cookie]}

      flows = []
      flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                             :eth_dst => datapath[:broadcast_mac_addr]
                           }, {}, actions)
      flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 90, {
                             :eth_src => datapath[:broadcast_mac_addr]
                           }, {}, actions)

      @datapath.add_flows(flows)

      self.update_network_id(dpn_map.network_id)
    end

    def prepare_network(network_map, dp_map)
      return unless network_map.network_mode == 'virtual'

      MW::DatapathNetwork.batch.on_segment(dp_map).where(:network_id => network_map.network_id).all.commit(:fill => :datapath).each { |dpn_map|
        self.insert(dpn_map, false)
      }

      self.update_network_id(network_map.network_id)
    end

    def remove_network_id(network_id)
      datapaths = @segment_datapaths.delete(network_id)

      return if datapaths.nil?

      datapaths.each { |dp|
        @datapath.del_cookie(dp[:cookie])
        @datapath.switch.cookie_manager.release(:dc_segment, dp[:cookie])
      }      
    end

    def update_network_id(network_id)
      eth_port = @datapath.switch.eth_ports.first
      datapaths = @segment_datapaths[network_id]

      return if eth_port.nil? || datapaths.nil?

      flood_actions = datapaths.collect { |datapath|
        { :eth_dst => datapath[:broadcast_mac_addr],
          :output => eth_port.port_number
        }
      }

      flood_actions << {:eth_dst => MAC_BROADCAST} unless flood_actions.empty?

      flows = []
      flows << Flow.create(TABLE_METADATA_SEGMENT, 1, {
                             :metadata => (network_id << METADATA_NETWORK_SHIFT) | OFPP_FLOOD,
                             :metadata_mask => METADATA_PORT_MASK | METADATA_NETWORK_MASK
                           }, flood_actions, {
                             :cookie => network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT),
                             :goto_table => TABLE_METADATA_TUNNEL
                           })
                           
      @datapath.add_flows(flows)
    end

  end

end    
