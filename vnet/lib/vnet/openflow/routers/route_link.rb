# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Routers

  class RouteLink
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :id
    attr_reader :uuid
    attr_reader :mac_address
    attr_reader :dp_mac_address

    attr_reader :routes

    def initialize(params)
      @dp_info = params[:dp_info]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid
      @mac_address = Trema::Mac.new(map.mac_address)
      @dp_mac_address = nil

      @routes = {}
      @datapaths_on_segment = {}
    end

    def cookie
      @id | COOKIE_TYPE_ROUTE_LINK
    end

    def install
      debug log_format('install', "mac:#{@mac_address}")

      flows = []

      flows_for_route_link(flows)
      flows_for_dp_route_link(flows) if @dp_mac_address

      @datapaths_on_segment.each { |datapath_id, dp_rl_info|
        flows_for_datapath_on_segment(flows, dp_rl_info)
      }

      @dp_info.add_flows(flows)
    end

    # Handle MAC2MAC packets for this route link using a unique MAC
    # address for this datapath, route link pair.
    def set_dp_route_link(dp_rl_map)
      @dp_mac_address = Trema::Mac.new(dp_rl_map.mac_address)

      # Install flows if activated.
    end

    # Use the datapath id in the metadata field and the route link
    # MAC address in the destination field to figure out the MAC2MAC
    # datapath, route link pair MAC address to use.
    #
    # If not found it is assumed to be using a tunnel where the
    # route link MAC address is to be used.
    def add_datapath_on_segment(dp_rl_map)
      return if @datapaths_on_segment.has_key? dp_rl_map.datapath_id

      @datapaths_on_segment[dp_rl_map.datapath_id] = {
        :datapath_id => dp_rl_map.datapath_id,
        :mac_address => Trema::Mac.new(dp_rl_map.mac_address),
      }

      # Install flows if activated.
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values)
      "#{@dp_info.dpid_s} routers/router_link: #{message} (route_link:#{@uuid}/#{@id}#{values ? ' ' : ''}#{values})"
    end

    def flows_for_route_link(flows)
      flows << flow_create(:default,
                           table: TABLE_TUNNEL_NETWORK_IDS,
                           goto_table: TABLE_ROUTE_LINK_EGRESS,
                           priority: 30,
                           match: {
                             :tunnel_id => TUNNEL_ROUTE_LINK,
                             :eth_dst => @mac_address
                           },
                           write_route_link: @id)
      flows << flow_create(:default,
                           table: TABLE_OUTPUT_ROUTE_LINK,
                           goto_table: TABLE_OUTPUT_ROUTE_LINK_HACK,
                           priority: 4,
                           match: {
                             :eth_dst => @mac_address
                           },
                           actions: {
                             :tunnel_id => TUNNEL_ROUTE_LINK
                           },
                           write_tunnel: nil)

      flows_for_filtering_mac_address(flows, @mac_address)
    end

    def flows_for_dp_route_link(flows)
      flows << flow_create(:default,
                           table: TABLE_HOST_PORTS,
                           goto_table: TABLE_ROUTE_LINK_EGRESS,
                           priority: 30,
                           match: {
                             :eth_dst => @dp_mac_address
                           },
                           write_route_link: @id)

      flows_for_filtering_mac_address(flows, @dp_mac_address)
    end

    def flows_for_datapath_on_segment(flows, dp_rl_info)
      flows << flow_create(:default,
                           table: TABLE_OUTPUT_ROUTE_LINK,
                           goto_table: TABLE_OUTPUT_ROUTE_LINK_HACK,
                           priority: 5,
                           match: {
                             :eth_dst => @mac_address
                           },
                           match_datapath: dp_rl_info[:datapath_id],
                           actions: {
                             :eth_dst => dp_rl_info[:mac_address]
                           },
                           write_mac2mac: true)

      flows_for_filtering_mac_address(flows, dp_rl_info[:mac_address])
    end

  end

end
