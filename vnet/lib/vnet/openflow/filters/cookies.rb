# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters::Cookies
  include Vnet::Constants::OpenflowFlows

  COOKIE_SG_TYPE_MASK = 0xf << COOKIE_TAG_SHIFT

  COOKIE_SG_TYPE_TAG  = 0x1 << COOKIE_TAG_SHIFT
  COOKIE_SG_TYPE_RULE = 0x2 << COOKIE_TAG_SHIFT
  COOKIE_SG_TYPE_REF  = 0x3 << COOKIE_TAG_SHIFT
  COOKIE_SG_TYPE_ISO  = 0x4 << COOKIE_TAG_SHIFT

  COOKIE_TYPE_VALUE_SHIFT = 36
  COOKIE_TYPE_VALUE_MASK  = 0xfffff << COOKIE_TYPE_VALUE_SHIFT

  COOKIE_TAG_INGRESS_ARP_ACCEPT = 0x1 << COOKIE_TYPE_VALUE_SHIFT
  COOKIE_TAG_INGRESS_ACCEPT_ALL = 0x2 << COOKIE_TYPE_VALUE_SHIFT

  def remove_all_rules_cookie(interface_id)
    sg_rules = COOKIE_TYPE_SECURITY_GROUP |
      COOKIE_SG_TYPE_RULE |
      interface.id << COOKIE_TYPE_VALUE_SHIFT

    sg_rules_mask = COOKIE_PREFIX_MASK | COOKIE_TAG_MASK

    [sg_rules, sg_rules_mask]
  end
end
