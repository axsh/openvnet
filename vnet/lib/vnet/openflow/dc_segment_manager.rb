# -*- coding: utf-8 -*-

module Vnet::Openflow

  class DcSegmentManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers

    def initialize(dp)
      @datapath = dp
      @datapath_networks = {}
    end

    def insert(dpn_map)
      dpn_list = (@datapath_networks[dpn_map.network_id] ||= {})

      if dpn_list.has_key? dpn_map.id
        warn "dc_segment_manager: datapath network id already exists (network_id:#{dpn_map.network_id}) dpn_id:#{dpn_map.id})"
        return
      end

      dpn = {
        :id => dpn_map.id,
        :broadcast_mac_address => Trema::Mac.new(dpn_map.broadcast_mac_address),
      }

      dpn_list[dpn_map.id] = dpn

      actions = {:cookie => dpn[:id] | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)}

      flows = []
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                             :eth_dst => dpn[:broadcast_mac_address]
                           }, nil, actions)
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                             :eth_src => dpn[:broadcast_mac_address]
                           }, nil, actions)
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                             :eth_dst => dpn[:broadcast_mac_address]
                           }, nil, actions)
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                             :eth_src => dpn[:broadcast_mac_address]
                           }, nil, actions)

      @datapath.add_flows(flows)

      self.update_network_id(dpn_map.network_id)
    end

    def prepare_network(network_map, dp_map)
      return unless network_map.network_mode == 'virtual'

      network_map.batch.datapath_networks_dataset.on_segment(dp_map).all.commit(:fill => :datapath).each { |dpn_map|
        self.insert(dpn_map)
      }

      cookie = network_map.network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)
      flow_options = {:cookie => cookie}
      nw_virtual_md = flow_options.merge(md_create(:network => network_map.network_id))

      dpn = network_map.batch.datapath_networks_dataset.on_specific_datapath(dp_map).first.commit

      flows = []
      flows << Flow.create(TABLE_HOST_PORTS, 30, {
                             :eth_dst => Trema::Mac.new(dpn.broadcast_mac_address)
                           }, {
                             :eth_dst => MAC_BROADCAST
                           }, nw_virtual_md.merge(:goto_table => TABLE_NETWORK_SRC_CLASSIFIER))

      @datapath.add_flows(flows)

      self.update_network_id(network_map.network_id)
    end

    def remove_network_id(network_id)
      dpn_list = @datapath_networks.delete(network_id)

      return if dpn_list.nil?

      dpn_list.each { |dpn|
        @datapath.del_cookie(dpn[:id] | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT))
      }
    end

    def update_network_id(network_id)
      eth_port = @datapath.port_manager.detect(port_type: :host)
      dpn_list = @datapath_networks[network_id]

      return if eth_port.nil? || dpn_list.nil?

      flood_actions = dpn_list.collect { |dpn_id,dpn|
        { :eth_dst => dpn[:broadcast_mac_address],
          :output => eth_port[:port_number]
        }
      }

      flood_actions << {:eth_dst => MAC_BROADCAST} unless flood_actions.empty?

      flows = []
      flows << Flow.create(TABLE_FLOOD_SEGMENT, 1,
                           md_create(network: network_id),
                           flood_actions, {
                             :cookie => network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT),
                             :goto_table => TABLE_FLOOD_TUNNEL_IDS
                           })

      @datapath.add_flows(flows)
    end

  end

end
