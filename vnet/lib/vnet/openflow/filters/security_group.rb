# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class SecurityGroup < Base
    include Celluloid::Logger

    attr_reader :id, :uuid

    def initialize(group_wrapper, interface_id)
      @id = group_wrapper.id
      @uuid = group_wrapper.uuid
      #TODO: Get the cookie id directly from the INITIALIZED_INTERFACE event instead?
      @interface_cookie_id = group_wrapper.batch.interface_cookie_id(interface_id).commit

      @rules = group_wrapper.rules.split("\n").map { |line|
        Rule.create(line, interface_id, cookie(:rule))
      }
      #TODO: Create reference rules
      #TODO: Create isolation
    end

    def self.cookie(group_id, interface_cookie_id, type)
      types = {
        rule: COOKIE_TYPE_RULE,
        reference: COOKIE_TYPE_REF,
        isolation: COOKIE_TYPE_ISO
      }

      group_id | COOKIE_TYPE_FILTER | types[type] |
        (interface_cookie_id << COOKIE_TYPE_VALUE_SHIFT)
    end

    def cookie(type)
      self.class.cookie(@id, @interface_cookie_id, type)
    end

    def install
      @rules.map { |rule| rule.install }
      #TODO: Install reference rules
      #TODO: Install isolation
    end

    def update_rules
      p "We're giving those rules a freaking updatin'"
      #TODO: Implement
    end

    def update_reference
      #TODO: Implement
    end

    def update_isolation
      #TODO: Implement
    end
  end

end
