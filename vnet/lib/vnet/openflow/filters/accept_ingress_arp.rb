# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class AcceptIngressArp < Base
    def self.cookie
      COOKIE_TYPE_FILTER |
      COOKIE_TYPE_TAG |
      COOKIE_TAG_INGRESS_ARP_ACCEPT
    end

    def install
      flow_create(:default,
                  table: TABLE_INTERFACE_INGRESS_FILTER,
                  priority: 90,
                  match: { eth_type: ETH_TYPE_ARP },
                  goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS)
    end
  end
end
