# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class SecurityGroup < Base
    include Celluloid::Logger

    attr_reader :id, :uuid

    def initialize(group_wrapper, interface_id)
      @id = group_wrapper.id
      @uuid = group_wrapper.uuid
      @interface_cookie_id = group_wrapper.batch.interface_cookie_id(interface_id).commit

      @rules = group_wrapper.rules.split("\n").map { |line|
        Rule.create(line, interface_id, cookie)
      }
    end

    def self.cookie(group_id, interface_cookie_id)
      group_id | COOKIE_TYPE_FILTER | COOKIE_TYPE_RULE |
        (interface_cookie_id << COOKIE_TYPE_VALUE_SHIFT)
    end

    def cookie
      self.class.cookie(@id, @interface_cookie_id)
    end

    def install
      @rules.map { |rule| rule.install }
    end
  end

end
