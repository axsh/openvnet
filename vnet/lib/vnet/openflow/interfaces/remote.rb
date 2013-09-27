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

    def add_ipv4_address(params)
      mac_info, ipv4_info = super

      flows = []
      flows_for_ipv4(flows,mac_info, ipv4_info)

      @datapath.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} interfaces/remote: #{message}" + (values ? " (#{values})" : '')
    end

    def install_ipv4(flows, mac_info, ipv4_info)
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

  end

end
