# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class AcceptAllTraffic < Base
    def initialize(interface_id, dp_info)
      @interface_id = interface_id
      @dp_info = dp_info
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
      @dp_info.add_flow flow_create(:default,
        table: TABLE_INTERFACE_INGRESS_FILTER,
        priority: 90,
        match_metadata: { interface: @interface_id },
        goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS
      )
    end

    def uninstall
      @dp_info.del_cookie cookie
    end
  end
end
