# -*- coding: utf-8 -*-

module Vnet::Core::Routers

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
      flows << flow_create(table: TABLE_ROUTER_CLASSIFIER_RL_NIL,
                           goto_table: TABLE_ROUTER_EGRESS_LOOKUP_RL_NIL,
                           priority: 30,

                           # TODO: Set FLAG_REFLECTION here?... If so don't set it in route_link_ingress(?)
                           match_first: @id,
                          )
    end

    def flows_for_route_link(flows)
      flows << flow_create(table: TABLE_CONTROLLER_PORT,
                           goto_table: TABLE_ROUTER_CLASSIFIER_RL_NIL,
                           priority: 30,

                           match: {
                             source_mac_address: @mac_address
                           },

                           write_reflection: false,
                           write_remote: true,
                           write_first: @id,
                           write_second: 0,
                          )

      flows << flow_create(table: TABLE_TUNNEL_IF_NIL,
                           goto_table: TABLE_ROUTER_CLASSIFIER_RL_NIL,
                           priority: 30,

                           match: {
                             tunnel_id: TUNNEL_ROUTE_LINK,
                             destination_mac_address: @mac_address
                           },

                           write_reflection: false,
                           write_first: @id,
                          )

      flows_for_filtering_mac_address(flows, @mac_address)
    end

  end

end
