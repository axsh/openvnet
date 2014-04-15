# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters

  class Base < Vnet::ItemBase
    include Vnet::Openflow::FlowHelpers

    attr_accessor :dp_info

    COOKIE_TYPE_MASK = 0xf << COOKIE_TAG_SHIFT

    COOKIE_TYPE_TAG  = 0x1 << COOKIE_TAG_SHIFT
    COOKIE_TYPE_RULE = 0x2 << COOKIE_TAG_SHIFT
    COOKIE_TYPE_REF  = 0x3 << COOKIE_TAG_SHIFT
    COOKIE_TYPE_ISO  = 0x4 << COOKIE_TAG_SHIFT

    COOKIE_TYPE_VALUE_SHIFT = 36
    COOKIE_TYPE_VALUE_MASK  = 0xfffff << COOKIE_TYPE_VALUE_SHIFT

    COOKIE_TAG_INGRESS_ARP_ACCEPT = 0x1 << COOKIE_TYPE_VALUE_SHIFT

    def initialize
      # TODO: Support proper params initialization:
      super({})
    end

    # We make a class method out of cookie so we can access
    # it easily in unit tests.
    def self.cookie
      raise NotImplementedError
    end

    def cookie
      self.class.cookie
    end

    def install
      raise NotImplementedError
    end

    def uninstall
      @dp_info.del_cookie(cookie)
    end

  end
end
