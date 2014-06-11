# -*- coding: utf-8 -*-

module Vnet::Core::ActiveInterfaces

  # TODO: Separate between singular remote and label'ed remotes.

  class Remote < Base

    def mode
      :remote
    end

    def log_type
      'active_interface/remote'
    end

    #
    # Events: 
    #

    def install
      flows = []
      flows_for_base(flows)
      flows_for_routing(flows) if @enable_routing

      @dp_info.add_flows(flows)
    end

    def uninstall
      @dp_info.del_cookie(self.cookie)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_base(flows)
      flows << flow_create(table: TABLE_LOOKUP_IF_NW_TO_DP_NW,
                           goto_table: TABLE_LOOKUP_DP_NW_TO_DP_NETWORK,
                           priority: 1,
                           match_value_pair_first: @interface_id,
                           write_value_pair_first: @datapath_id)
    end

    def flows_for_routing(flows)
      flows << flow_create(table: TABLE_ROUTE_EGRESS_LOOKUP,
                           goto_table: TABLE_LOOKUP_IF_RL_TO_DP_RL,
                           priority: 10,
                           match_value_pair_first: @interface_id)
      flows << flow_create(table: TABLE_LOOKUP_IF_RL_TO_DP_RL,
                           goto_table: TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK,
                           priority: 1,
                           match_value_pair_first: @interface_id,
                           write_value_pair_first: @datapath_id)
    end

  end

end
