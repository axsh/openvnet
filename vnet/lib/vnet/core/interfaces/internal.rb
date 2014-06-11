# -*- coding: utf-8 -*-

module Vnet::Core::Interfaces

  class Internal < IfBase

    def log_type
      'interface/internal'
    end

    def add_mac_address(params)
      mac_info = super || return

      flows = []
      flows_for_mac(flows, mac_info)
      flows_for_interface_mac(flows, mac_info)

      @dp_info.add_flows(flows)
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super || return

      flows = []
      flows_for_interface_ipv4(flows, mac_info, ipv4_info)

      @dp_info.add_flows(flows)
    end

    def install
      flows = []
      flows_for_base(flows)
      flows_for_disabled_filtering(flows) unless @ingress_filtering_enabled

      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_base(flows)
      flows << flow_create(table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 10,
                           match_interface: @id,
                           actions: {
                             :output => OFPP_LOCAL
                           })
    end

    def flows_for_mac(flows, mac_info)
      cookie = self.cookie_for_mac_lease(mac_info[:cookie_id])

      #
      # Classifiers:
      #
      flows << flow_create(table: TABLE_LOCAL_PORT,
                           goto_table: TABLE_INTERFACE_EGRESS_CLASSIFIER,
                           priority: 30,

                           match: {
                             :eth_src => mac_info[:mac_address],
                           },
                           write_interface: @id,
                           cookie: cookie)
    end

  end

end
