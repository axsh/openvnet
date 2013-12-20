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

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} interfaces/remote: #{message}" + (values ? " (#{values})" : '')
    end

    def flows_for_ipv4(flows, mac_info, ipv4_info)
      flows << flow_create(:router_dst_match,
                           priority: 40,
                           match: {
                             :eth_type => 0x0800,
                             :ipv4_dst => ipv4_info[:ipv4_address],
                           },
                           actions: {
                             :eth_dst => mac_info[:mac_address],
                           },
                           network_id: ipv4_info[:network_id])
    end

    #
    # Not needed unless egress routing is used:
    #
    def flows_for_router_egress_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      datapath_id = @owner_datapath_ids && @owner_datapath_ids.first
      return if datapath_id.nil?

      flows << flow_create(:default,
                           table: TABLE_ROUTE_EGRESS_INTERFACE,
                           goto_table: TABLE_OUTPUT_ROUTE_LINK,
                           priority: 20,
                           match_interface: @id,
                           write_datapath: datapath_id,
                           cookie: cookie)
    end    

  end

end
