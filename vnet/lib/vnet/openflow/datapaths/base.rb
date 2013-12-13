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

      @active_route_links = {}
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
      case @mode
      when :tunnel
        @dp_info.tunnel_manager.async.create_item(dst_id: id)
      end
    end

    def uninstall
      @dp_info.del_cookie(id | COOKIE_TYPE_DATAPATH)
      @active_networks.each do |_, active_network|
        @dp_info.del_cookie(active_network[:dpn_id] | COOKIE_TYPE_DP_NETWORK)
      end

      case @mode
      when :owner
        @dp_info.interface_manager.update_item(event: :remove_all_active_datapath)
        @dp_info.datapath.reset
      when :segment
        @dp_info.dc_segment_manager.async.remove_datapath(id)
      when :tunnel
        @dp_info.tunnel_manager.async.unload(dst_id: id)
      end
    end

    #
    # Networks:
    #

    def add_active_network(dpn_map)
      return if @active_networks.has_key? dpn_map.network_id

      active_network = {
        :id => dpn_map.id,
        :dpn_id => dpn_map.id,
        :datapath_id => dpn_map.datapath_id,
        :interface_id => dpn_map.interface_id,
        :network_id => dpn_map.network_id,

        :mac_address => Trema::Mac.new(dpn_map.broadcast_mac_address),
        :broadcast_mac_address => Trema::Mac.new(dpn_map.broadcast_mac_address),
      }

      @active_networks[dpn_map.network_id] = active_network

      flows = []
      flows_for_filtering_mac_address(flows,
                                      active_network[:broadcast_mac_address],
                                      active_network[:dpn_id] | COOKIE_TYPE_DP_NETWORK)
      flows_for_dp_network(flows, active_network)

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

      debug log_format("adding to #{@uuid}/#{id} active datapath network #{dpn_map.datapath_id}/#{dpn_map.network_id}")
    end

    def remove_active_network_id(network_id)
      active_network = @active_networks.delete(network_id)
      return false if active_network.nil?

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
      
      debug log_format("removing from #{@uuid}/#{id} active datapath network #{network_id}")

      true
    end

    #
    # Route links:
    #

    def add_active_route_link(dp_rl_map)
      return if dp_rl_map.route_link.nil?
      return if @active_route_links.has_key? dp_rl_map.route_link_id

      dp_rl = {
        :id => dp_rl_map.id,
        :datapath_id => dp_rl_map.datapath_id,
        :interface_id => dp_rl_map.interface_id,
        :mac_address => Trema::Mac.new(dp_rl_map.mac_address),

        :route_link_id => dp_rl_map.route_link_id,
        :route_link_mac_address => Trema::Mac.new(dp_rl_map.route_link.mac_address),
      }

      @active_route_links[dp_rl_map.route_link_id] = dp_rl

      return if dp_rl[:interface_id].nil?
      return if dp_rl[:datapath_id].nil?
      return if dp_rl[:route_link_id].nil?
      return if dp_rl[:route_link_mac_address].nil?

      flows = []
      flows_for_filtering_mac_address(flows,
                                      dp_rl[:mac_address],
                                      dp_rl[:id] | COOKIE_TYPE_DP_ROUTE_LINK)
      flows_for_dp_route_link(flows, dp_rl)

      @dp_info.add_flows(flows)

      debug log_format("adding to #{@uuid}/#{id} active datapath route link #{dp_rl_map.datapath_id}/#{dp_rl_map.route_link_id}")
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

    def flows_for_dp_route_link(flows, dp_rl)
    end

  end
end
