# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  # Remote interface types are any type of interface that is located
  # on other datapaths.

  class Remote < Base

    def initialize(params)
      super

      @remote_mode = @mode
      @mode = :remote
    end

    def add_mac_address(params)
      mac_info = super

      # flows = []
      # @dp_info.add_flows(flows)
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      # flows = []
      # @dp_info.add_flows(flows)
    end

    def enable_router_egress
      return if @router_egress != false
      @router_egress = true
    end

    def disable_router_egress
      # Not supported atm.
    end

    def install
      flows = []
      flows_for_base(flows)
      flows_for_datapath(flows)
      
      @dp_info.add_flows(flows)
    end

    def update_remote_datapath(params)
      @active_datapath_ids = [params[:datapath_id]]
      
      flows = []
      flows_for_datapath(flows)
      
      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} interfaces/remote: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_base(flows)
      # TODO: Only add when router egress is set.
      flows << flow_create(:default,
                           table: TABLE_ROUTE_EGRESS_LOOKUP,
                           goto_table: TABLE_LOOKUP_IF_RL_TO_DP_RL,
                           priority: 1,

                           match_value_pair_first: @id)
    end

    def flows_for_datapath(flows)
      datapath_id = @active_datapath_ids && @active_datapath_ids.first
      return if datapath_id.nil?

      flows << flow_create(:default,
                           table: TABLE_LOOKUP_IF_NW_TO_DP_NW,
                           goto_table: TABLE_LOOKUP_DP_NW_TO_DP_NETWORK,
                           priority: 1,

                           match_value_pair_first: @id,
                           write_value_pair_first: datapath_id)
      flows << flow_create(:default,
                           table: TABLE_LOOKUP_IF_RL_TO_DP_RL,
                           goto_table: TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK,
                           priority: 1,

                           match_value_pair_first: @id,
                           write_value_pair_first: datapath_id)
    end

  end

end
