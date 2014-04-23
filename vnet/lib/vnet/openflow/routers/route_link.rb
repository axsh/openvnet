# -*- coding: utf-8 -*-

module Vnet::Openflow::Routers

  class RouteLink < Base

    def log_type
      'router/route_link'
    end

    #
    # Events: 
    #

    def install
      flows = []
      flows_for_dynamic_load(flows)
      flows_for_route_link(flows)

      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_dynamic_load(flows)
      flows << flow_create(:default,
                           table: TABLE_ROUTER_CLASSIFIER,
                           goto_table: TABLE_ROUTER_EGRESS_LOOKUP,
                           priority: 30,

                           # TODO: Set reflection flag here?... If so don't set it in route_link_ingress(?)
                           match_route_link: @id)
    end

    def flows_for_route_link(flows)
      flows << flow_create(:default,
                           table: TABLE_CONTROLLER_PORT,
                           goto_table: TABLE_ROUTER_CLASSIFIER,
                           priority: 30,

                           match: {
                             :eth_src => @mac_address
                           },
                           write_route_link: @id)

      flows << flow_create(:default,
                           table: TABLE_TUNNEL_NETWORK_IDS,
                           goto_table: TABLE_ROUTER_CLASSIFIER,
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
