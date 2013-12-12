# -*- coding: utf-8 -*-

module Vnet::Openflow::Datapaths

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_accessor :id
    attr_accessor :uuid

    def initialize(params)
      @dp_info = params[:dp_info]
      @manager = params[:manager]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid

      @active_networks = {}
      @active_route_links = {}
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

    def is_unused?
      return false if !@active_networks.empty?
      true
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

      @dp_info.add_flows(flows)

      debug log_format("adding to #{@uuid}/#{id} active datapath network #{dpn_map.datapath_id}/#{dpn_map.network_id}")
    end

    def remove_active_network_id(network_id)
      active_network = @active_networks.delete(network_id)
      return false if active_networks.nil?

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

    def flows_for_dp_route_link(flows, dp_rl)
    end

  end

end
