# -*- coding: utf-8 -*-

module Vnet::Openflow::Routers

  class RouteLink < Base

    #
    # Events: 
    #

    def install
      flows = []
      flows_for_dynamic_load(flows)
      flows_for_route_link(flows)

      @dp_info.add_flows(flows)

      debug log_format('install', "mac_address:#{@mac_address}")
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} routers/router_link: #{message} (route_link:#{@uuid}/#{@id}#{values ? ' ' : ''}#{values})"
    end

    def flows_for_dynamic_load(flows)
      flows << flow_create(:default,
                           table: TABLE_ROUTE_LINK_EGRESS,
                           priority: 10,

                           match_route_link: @id)
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

      flows_for_filtering_mac_address(flows, @mac_address)
    end

  end

end
