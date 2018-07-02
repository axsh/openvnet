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

      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_dynamic_load(flows)
      flows << flow_create(table: TABLE_ROUTER_CLASSIFIER,
                           goto_table: TABLE_ROUTER_EGRESS_LOOKUP,
                           priority: 30,

                           # TODO: Set reflection flag here?... If so don't set it in route_link_ingress(?)
                           match_route_link: @id)
    end

  end

end
