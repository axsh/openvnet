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
      @active_segments = {}
      @active_route_links = {}
    end

    def host?
      false
    end

    def mode
      :base
    end

    def log_type
      'datapath/base'
    end

    def pretty_properties
      "mode:#{self.mode}"
    end

    def cookie(tag = nil)
      value = @id | COOKIE_TYPE_INTERFACE
      tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    end

    def to_hash
      # TODO: Remove active_networks?
      Vnet::Core::Datapath.new(id: @id,
                               uuid: @uuid,
                               display_name: @display_name,
                               node_id: @node_id,

                               active_networks: @active_networks.values)
    end

    def unused?
      !!(@active_networks.empty? && @active_segments.empty? && @active_route_links.empty?)
    end

    def has_active_network?(network_id)
      !!@active_networks.detect { |id, active_network|
        active_network[:network_id] == network_id
      }
    end

    def has_active_segment?(segment_id)
      !!@active_segments.detect { |id, active_segment|
        active_segment[:segment_id] == segment_id
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

    def uninstall
      @dp_info.del_cookie(id | COOKIE_TYPE_DATAPATH)

      @active_networks.each do |_, active_network|
        @dp_info.del_cookie(active_network[:id] | COOKIE_TYPE_DP_NETWORK)
      end

      @active_segments.each do |_, active_segment|
        @dp_info.del_cookie(active_segment[:id] | COOKIE_TYPE_DP_SEGMENT)
      end

      @active_route_links.each do |_, active_route_link|
        @dp_info.del_cookie(active_route_link[:id] | COOKIE_TYPE_DP_ROUTE_LINK)
      end
    end

    #
    # Networks:
    #

    def add_active_network(dpg_map)
      network_id = get_param_id(dpg_map, :network_id)

      return if @active_networks.has_key? network_id

      dp_network = {
        id: get_param_id(dpg_map),
        datapath_id: get_param_id(dpg_map, :datapath_id),
        interface_id: get_param_id(dpg_map, :interface_id),
        network_id: get_param_id(dpg_map, :network_id),
        ip_lease_id: get_param_id(dpg_map, :ip_lease_id),
        mac_address: get_param_mac_address(dpg_map),

        active: false
      }

      @active_networks[network_id] = dp_network

      flows = []
      flows_for_dp_network(flows, dp_network)
      @dp_info.add_flows(flows)

      debug log_format("adding datapath network #{network_id} to #{self.pretty_id}")
    end

    def remove_active_network(network_id)
      dp_network = @active_networks.delete(network_id)
      return false if dp_network.nil?

      @dp_info.del_cookie(dp_network[:id] | COOKIE_TYPE_DP_NETWORK)

      debug log_format("removing datapath network #{network_id} from #{self.pretty_id}")
    end

    #
    # Segments:
    #

    def add_active_segment(dpg_map)
      segment_id = get_param_id(dpg_map, :segment_id)

      return if @active_segments.has_key? segment_id

      dp_segment = {
        id: get_param_id(dpg_map),
        datapath_id: get_param_id(dpg_map, :datapath_id),
        interface_id: get_param_id(dpg_map, :interface_id),
        segment_id: get_param_id(dpg_map, :segment_id),
        ip_lease_id: get_param_id(dpg_map, :ip_lease_id),
        mac_address: get_param_mac_address(dpg_map),

        active: false
      }

      @active_segments[segment_id] = dp_segment

      flows = []
      flows_for_dp_segment(flows, dp_segment)
      @dp_info.add_flows(flows)

      debug log_format("adding datapath segment #{segment_id} to #{self.pretty_id}")
    end

    def remove_active_segment(segment_id)
      dp_segment = @active_segments.delete(segment_id)
      return false if dp_segment.nil?

      @dp_info.del_cookie(dp_segment[:id] | COOKIE_TYPE_DP_SEGMENT)

      debug log_format("removing datapath segment #{segment_id} from #{self.pretty_id}")
    end

    #
    # Route links:
    #

    def add_active_route_link(dpg_map)
      route_link_id = get_param_id(dpg_map, :route_link_id)

      return if @active_route_links.has_key? route_link_id

      dp_route_link = {
        id: get_param_id(dpg_map),
        datapath_id: get_param_id(dpg_map, :datapath_id),
        interface_id: get_param_id(dpg_map, :interface_id),
        route_link_id: get_param_id(dpg_map, :route_link_id),
        ip_lease_id: get_param_id(dpg_map, :ip_lease_id),
        mac_address: get_param_mac_address(dpg_map),

        active: false
      }

      @active_route_links[route_link_id] = dp_route_link

      flows = []
      flows_for_dp_route_link(flows, dp_route_link)
      @dp_info.add_flows(flows)

      debug log_format("adding datapath route link #{route_link_id} to #{self.pretty_id}")
    end

    def remove_active_route_link(route_link_id)
      dp_route_link = @active_route_links.delete(route_link_id)
      return false if dp_route_link.nil?

      @dp_info.del_cookie(dp_route_link[:id] | COOKIE_TYPE_DP_ROUTE_LINK)

      debug log_format("removing datapath route link #{route_link_id} from #{self.pretty_id}")
    end

    #
    # Internal methods:
    #

    private

  end
end
