# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class AcceptAllTraffic < Base
    def initialize(interface_id)
      @interface_id = interface_id
    end

    def self.cookie(interface_id)
      interface_id |
        COOKIE_TYPE_FILTER |
        COOKIE_TYPE_TAG |
        COOKIE_TAG_INGRESS_ACCEPT_ALL
    end

    def cookie
      self.class.cookie(@interface_id)
    end

    def install
      [
        flow_create(:default,
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: Vnet::Openflow::Filters::Rule::PRIORITY,
          match_metadata: { interface: @interface_id },
          goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS)
      ]
    end
  end
end
