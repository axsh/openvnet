# -*- coding: utf-8 -*-

module Vnet::Openflow
  class SecurityGroupManager < Manager
    include Vnet::Openflow::FlowHelpers

    COOKIE_SG_TYPE_MASK = 0xf << COOKIE_TAG_SHIFT

    COOKIE_SG_TYPE_TAG  = 0x1 << COOKIE_TAG_SHIFT
    COOKIE_SG_TYPE_RULE = 0x2 << COOKIE_TAG_SHIFT
    COOKIE_SG_TYPE_REF  = 0x3 << COOKIE_TAG_SHIFT
    COOKIE_SG_TYPE_ISO  = 0x4 << COOKIE_TAG_SHIFT

    COOKIE_TYPE_VALUE_SHIFT = 36
    COOKIE_TYPE_VALUE_MASK  = 0xfffff << COOKIE_TYPE_VALUE_SHIFT

    COOKIE_TAG_INGRESS_ARP_ACCEPT = 0x1 << COOKIE_TYPE_VALUE_SHIFT
    COOKIE_TAG_INGRESS_ACCEPT_ALL = 0x2 << COOKIE_TYPE_VALUE_SHIFT

    def initialize(*args)
      super(*args)

      accept_ingress_arp
    end

    def apply_rules(openflow_interface)
      interface_id = openflow_interface.id
      interface = MW::Interface.batch[interface_id].commit

      groups = interface.batch.security_groups.commit.map { |g|
        Vnet::Openflow::SecurityGroups::Group.new(g, interface_id)
      }

      flows = if groups.empty?
        accept_all_traffic(interface_id)
      else
        groups.map { |g| g.install(interface) }.flatten
      end

      @dp_info.add_flows(flows)
    end

    def remove_rules(interface)
      @dp_info.del_cookie(accept_all_traffic_cookie(interface.id))

      sg_rules = COOKIE_TYPE_SECURITY_GROUP |
        COOKIE_SG_TYPE_RULE |
        interface.id << COOKIE_TYPE_VALUE_SHIFT

      sg_rules_mask = COOKIE_PREFIX_MASK | COOKIE_TAG_MASK

      @dp_info.del_cookie(sg_rules, sg_rules_mask)
    end

    private
    def accept_all_traffic_cookie(interface_id)
      interface_id |
        COOKIE_TYPE_SECURITY_GROUP |
        COOKIE_SG_TYPE_TAG |
        COOKIE_TAG_INGRESS_ACCEPT_ALL
    end

    def accept_all_traffic(interface_id)
      [
        flow_create(:default,
          table: TABLE_INTERFACE_INGRESS_FILTER,
          priority: Vnet::Openflow::SecurityGroups::RULE_PRIORITY,
          idle_timeout: Vnet::Openflow::SecurityGroups::IDLE_TIMEOUT,
          cookie: accept_all_traffic_cookie(interface_id),
          match_metadata: { interface: interface_id },
          goto_table: TABLE_INTERFACE_VIF)
      ]
    end

    def accept_ingress_arp
      cookie = COOKIE_TYPE_SECURITY_GROUP |
        COOKIE_SG_TYPE_TAG |
        COOKIE_TAG_INGRESS_ARP_ACCEPT

      @dp_info.add_flows [
        flow_create(:default,
                    table: TABLE_INTERFACE_INGRESS_FILTER,
                    priority: 100,
                    cookie: cookie,
                    match: { eth_type: ETH_TYPE_ARP },
                    goto_table: TABLE_INTERFACE_VIF)
      ]
    end
  end
end
