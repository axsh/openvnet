# -*- coding: utf-8 -*-

module Vnet::Core::Filters
  class AcceptEgressArp < Base
    def self.cookie
      COOKIE_TYPE_FILTER |
        COOKIE_TYPE_TAG |
        COOKIE_TAG_EGRESS_ARP_ACCEPT
    end

    # Just something to identify this thing with in @items in filter manager
    def id
      'accept_egress_arp'
    end

    def install
      @dp_info.add_flow(
        flow_create(table: TABLE_INTERFACE_EGRESS_FILTER,
                    priority: 90,
                    match: { eth_type: ETH_TYPE_ARP },
                    goto_table: TABLE_INTERFAC_EGRESS_VALIDATE)
      )
    end
  end
end
