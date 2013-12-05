# -*- coding: utf-8 -*-

module Vnet::Openflow::Datapaths

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :id
    attr_reader :uuid
    attr_reader :mode

    def initialize(params)
      @dp_info = params[:dp_info]
      @manager = params[:manager]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @dpid = map.dpid.hex

      @active_networks = {}

      @mode =
        if map.dpid == @dp_info.dpid_s
          :owner
        elsif map.dc_segment_id == params[:owner_dc_segment_id]
          :segment
        else
          :tunnel
        end
    end
    
    def owner?
      @mode == :owner
    end

    def cookie(tag = nil)
      value = @id | COOKIE_TYPE_INTERFACE
      tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    end

    def to_hash
      { :id => @id,
        :uuid => @uuid,
      }
    end

    def unused?
      !!@active_networks.empty?
    end

    def install
    end

    def uninstall
      # debug log_format("removing flows")

      # cookie_value = self.cookie
      # cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK

      # @dp_info.del_cookie(cookie_value, cookie_mask)
    end

    #
    # Networks:
    #

    def add_active_network(dpn_map)
      debug log_format("adding to #{@uuid}/#{id} active datapath network #{dpn_map.datapath_id}/#{dpn_map.network_id}")

      return if @active_networks.has_key? dpn_map.id

      active_network = {
        :dpn_id => dpn_map.id,
        :datapath_id => dpn_map.datapath_id,
        :network_id => dpn_map.network_id,
        :broadcast_mac_address => Trema::Mac.new(dpn_map.broadcast_mac_address),
      }

      @active_networks[dpn_map.network_id] = active_network

      flows = []
      flows_for_filtering_mac_address(flows,
                                      active_network[:broadcast_mac_address],
                                      active_network[:dpn_id] | COOKIE_TYPE_DP_NETWORK)

      case @mode
      when :owner
        flows_for_broadcast_mac_address(
          flows,
          active_network[:broadcast_mac_address],
          active_network[:dpn_id] | COOKIE_TYPE_DP_NETWORK
        )
        @dp_info.dc_segment_manager.async.prepare_network(active_network[:network_id])
        # nothing to do
        @dp_info.tunnel_manager.async.prepare_network(active_network[:network_id])
      when :segment
        @dp_info.dc_segment_manager.async.insert(active_network[:dpn_id])
      when :tunnel
        @dp_info.tunnel_manager.async.insert(active_network[:dpn_id])
      end

      @dp_info.add_flows(flows)
    end

    def remove_active_network_id(network_id)
      active_network = @active_networks.delete(network_id)
      return false if active_network.nil?

      debug log_format("removing from #{@uuid}/#{id} active datapath network #{network_id}")

      case @mode
      when :owner
        @dp_info.dc_segment_manager.async.remove_network_id(network_id)
        @dp_info.tunnel_manager.async.remove_network_id_for_dpid(network_id, @dpid)
      when :segment
        @dp_info.dc_segment_manager.async.remove(active_network[:dpn_id])
      when :tunnel
        @dp_info.tunnel_manager.async.remove_network_id_for_dpid(network_id, @dpid)
      end

      @dp_info.del_cookie(active_network[:dpn_id] | COOKIE_TYPE_DP_NETWORK)
      
      true
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapaths/base: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_broadcast_mac_address(flows, broadcast_mac_address, cookie)
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                             :eth_dst => broadcast_mac_address
                           }, {}, cookie: cookie)
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                             :eth_src => broadcast_mac_address
                           }, {}, cookie: cookie)
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                             :eth_dst => broadcast_mac_address
                           }, {}, cookie: cookie)
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                             :eth_src => broadcast_mac_address
                           }, {}, cookie: cookie)
    end
  end
end
