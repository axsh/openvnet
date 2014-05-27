# -*- coding: utf-8 -*-

module Vnet::Core::Datapaths

  class Base < Vnet::ItemDpUuid
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :display_name
    attr_reader :dpid
    attr_reader :node_id

    def initialize(params)
      super

      map = params[:map]

      @display_name = map.display_name
      @dpid = map.dpid
      @node_id = map.node_id

      @active_networks = {}
      @active_route_links = {}
    end

    def host?
      false
    end

    def log_type
      'datapath/base'
    end

    def cookie(tag = nil)
      value = @id | COOKIE_TYPE_INTERFACE
      tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    end

    def to_hash
      {
        id: @id,
        uuid: @uuid,
        active_networks: @active_networks.values,
      }
    end

    def unused?
      !!(@active_networks.empty? && @active_route_links.empty?)
    end

    def has_active_network?(network_id)
      !!@active_networks.detect { |id, active_network|
        active_network[:network_id] == network_id
      }
    end

    def has_active_route_link?(route_link_id)
      !!@active_route_links.detect { |id, active_route_link|
        active_route_link[:route_link_id] == route_link_id
      }
    end

    #
    # Events:
    #

    def install
    end

    def uninstall
      @dp_info.del_cookie(id | COOKIE_TYPE_DATAPATH)

      @active_networks.each do |_, active_network|
        @dp_info.del_cookie(active_network[:id] | COOKIE_TYPE_DP_NETWORK)
      end
      @active_route_links.each do |_, active_route_link|
        @dp_info.del_cookie(active_route_link[:id] | COOKIE_TYPE_DP_ROUTE_LINK)
      end
    end

    #
    # Networks:
    #

    # TODO: RENAME from active network...

    def add_active_network(dpn_map)
      return if dpn_map.network_id.nil?
      return if @active_networks.has_key? dpn_map.network_id

      dp_network = {
        id: dpn_map.id || return,
        datapath_id: dpn_map.datapath_id || return,
        interface_id: dpn_map.interface_id || return,
        network_id: dpn_map.network_id || return,
        mac_address: Trema::Mac.new(dpn_map.broadcast_mac_address || return),

        active: false
      }

      @active_networks[dpn_map.network_id] = dp_network

      flows = []
      flows_for_filtering_mac_address(flows,
                                      dp_network[:mac_address],
                                      dp_network[:id] | COOKIE_TYPE_DP_NETWORK)
      flows_for_dp_network(flows, dp_network)

      @dp_info.add_flows(flows)

      debug log_format("adding to #{@uuid}/#{@id} datapath network #{dpn_map.network_id}")
    end

    def remove_active_network(network_id)
      dp_network = @active_networks.delete(network_id)
      return false if dp_network.nil?

      @dp_info.del_cookie(dp_network[:id] | COOKIE_TYPE_DP_NETWORK)

      debug log_format("removing from #{@uuid}/#{@id} datapath network #{network_id}")
    end

    #
    # Route links:
    #

    def add_active_route_link(dprl_map)
      return if dprl_map.route_link_id.nil?
      return if @active_route_links.has_key? dprl_map.route_link_id

      dp_route_link = {
        id: dprl_map.id || return,
        datapath_id: dprl_map.datapath_id || return,
        interface_id: dprl_map.interface_id || return,
        route_link_id: dprl_map.route_link_id || return,
        mac_address: Trema::Mac.new(dprl_map.mac_address || return),

        active: false
      }

      @active_route_links[dprl_map.route_link_id] = dp_route_link

      return if dp_route_link[:interface_id].nil?
      return if dp_route_link[:datapath_id].nil?
      return if dp_route_link[:route_link_id].nil?

      flows = []
      flows_for_filtering_mac_address(flows,
                                      dp_route_link[:mac_address],
                                      dp_route_link[:id] | COOKIE_TYPE_DP_ROUTE_LINK)
      flows_for_dp_route_link(flows, dp_route_link)

      @dp_info.add_flows(flows)

      debug log_format("adding to #{@uuid}/#{@id} datapath route link #{dprl_map.route_link_id}")
    end

    #
    # Internal methods:
    #

    private

    def flows_for_dp_route_link(flows, dp_rl)
    end

  end
end
