# -*- coding: utf-8 -*-

module Vnet::Openflow
  class SecurityGroupManager < Manager
    # include Vnet::Openflow::FlowHelpers

    def insert_catch_flow(vif)
      flows = [
        vif.flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER,
                    priority: 1,
                    match_metadata: {
                      :interface => vif.id
                    },
                    actions: {
                      :output => Controller::OFPP_CONTROLLER
                    })
        #TODO: Insert a drop flow with very low timeout to avoid flooding
        #the controller
      ]

      @dp_info.add_flows(flows)
    end
  end
end
