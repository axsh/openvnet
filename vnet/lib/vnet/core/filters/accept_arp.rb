# -*- coding: utf-8 -*-

module Vnet::Core::Filters
  class AcceptArp < Base
    def self.cookie
      COOKIE_TYPE_FILTER |
      COOKIE_TYPE_TAG |
      COOKIE_TAG_INGRESS_ARP_ACCEPT
    end

    # Just something to identify this thing with in @items in filter manager
    def id
      'accept_arp'
    end

    def install
      
      flows = []

      flows << flow_create(
        table: TABLE_INTERFACE_INGRESS_FILTER,
        goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
        priority: 90,
        match: { eth_type: ETH_TYPE_ARP }
      )

      flows << flow_create(
        table: TABLE_INTERFACE_EGRESS_FILTER,
        goto_table: TABLE_INTERFACE_EGRESS_VALIDATE,
        priority: 90,
        match: { eth_type: ETH_TYPE_ARP }
      )

      @dp_info.add_flows(flows)
    end
  end
end
