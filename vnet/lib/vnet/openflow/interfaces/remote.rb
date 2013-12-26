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

      flows = []
      flows_for_router_egress_mac(flows, mac_info) if @router_egress == true

      @dp_info.add_flows(flows)
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      flows = []
      flows_for_ipv4(flows,mac_info, ipv4_info)
      flows_for_router_egress_ipv4(flows, mac_info, ipv4_info) if @router_egress == true

      @dp_info.add_flows(flows)
    end

    def enable_router_egress
      return if @router_egress != false
      @router_egress = true

      flows = []

      @mac_addresses.each { |mac_lease_id, mac_info|
        flows_for_router_egress_mac(flows, mac_info)

        mac_info[:ipv4_addresses].each { |ipv4_info|
          flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
        }
      }

      @dp_info.add_flows(flows)
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
                           
                           # write_value_pair_first: @id,
                           # write_value_pair_second: )
    end

    def flows_for_datapath(flows)
      datapath_id = @active_datapath_ids && @active_datapath_ids.first
      # datapath_id = @owner_datapath_ids && @owner_datapath_ids.first if datapath_id.nil?
      return if datapath_id.nil?

      flows << flow_create(:default,
                           table: TABLE_LOOKUP_IF_NW_TO_DP_NW,
                           goto_table: TABLE_LOOKUP_DP_NW_TO_DP_NETWORK,
                           priority: 1,

                           match_value_pair_first: @id,
                           write_value_pair_first: datapath_id,

                           cookie: cookie)
      flows << flow_create(:default,
                           table: TABLE_LOOKUP_IF_RL_TO_DP_RL,
                           goto_table: TABLE_LOOKUP_DP_RL_TO_DP_ROUTE_LINK,
                           priority: 1,

                           match_value_pair_first: @id,
                           write_value_pair_first: datapath_id,

                           cookie: cookie)
    end

    def flows_for_ipv4(flows, mac_info, ipv4_info)
      cookie = self.cookie_for_ip_lease(ipv4_info[:cookie_id])

      # TODO: Change this to if nw:
      # flows << flow_create(:router_dst_match,
      #                      priority: 40,
      #                      match: {
      #                        :eth_type => 0x0800,
      #                        :ipv4_dst => ipv4_info[:ipv4_address],
      #                      },
      #                      actions: {
      #                        :eth_dst => mac_info[:mac_address],
      #                      },
      #                      network_id: ipv4_info[:network_id])
    end

    def flows_for_router_egress_mac(flows, mac_info)
    end    

  end

end
