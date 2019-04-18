# -*- coding: utf-8 -*-

module Vnet::Core::Networks

  class Internal < Base

    def network_type
      :internal
    end

    def log_type
      'network/internal'
    end

    def install
      flows = []
      flows << flow_create(table: TABLE_NETWORK_SRC_CLASSIFIER_NW_NIL,
                           goto_table: TABLE_ROUTE_INGRESS_INTERFACE_NW_NIL,
                           priority: 30,
                           match_first: @id,
                          )
      flows << flow_create(table: TABLE_NETWORK_DST_CLASSIFIER_NW_NIL,
                           goto_table: TABLE_NETWORK_DST_MAC_LOOKUP_NIL_NW,
                           priority: 30,
                           match_first: @id,

                           write_first: 0,
                           write_second: @id,
                          )

      @dp_info.add_flows(flows)
    end

    def update_flows(port_numbers)
      local_actions = port_numbers.collect { |port_number|
        { :output => port_number }
      }

      # Include port LOCAL until we implement interfaces for local eth
      # ports.
      local_actions << { :output => OFPP_LOCAL }

      # TODO: Require matching IPv4? Probably do it in TABLE_NETWORK_DST_MAC_LOOKUP_NIL_NW.

      flows = []
      flows << flow_create(table: TABLE_FLOOD_LOCAL_SEG_NW,
                           # goto_table: TABLE_LOOKUP_NW_NIL,
                           priority: 1,
                           match_network: @id,
                           actions: local_actions)

      @dp_info.add_flows(flows)
    end

  end

end
