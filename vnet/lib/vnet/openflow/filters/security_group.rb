# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class SecurityGroup < Base
    include Celluloid::Logger

    attr_reader :id, :uuid

    def initialize(params)
      @id = params[:id]
      @uuid = params[:uuid]
      @interface_id = params[:interface_id]
      @interface_cookie_id = params[:interface_cookie_id]

      set_rules params[:rules]
      #TODO: Create reference rules
      #TODO: Create isolation
    end

    def dp_info=(dpi)
      super
      @rules.each { |r| r.dp_info = dpi }
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

    def uninstall
      @rules.map { |rule| rule.uninstall }
      #TODO: Uninstall reference rules
      #TODO: Uninstall isolation
    end

    def update_rules(rules)
      uninstall_rules
      set_rules(rules)
      install_rules
    end

    def update_reference
      #TODO: Implement
    end

    def update_isolation
      #TODO: Implement
    end

    private
    def set_rules(rules)
      @rules = rules.split("\n").map { |line|
        Rule.create(line, @interface_id, cookie(:rule)).tap do |r|
          r.dp_info = dp_info
        end
      }
    end

    def install_rules
      @rules.map { |rule| rule.install }
    end

    def uninstall_rules
      @dp_info.del_cookie cookie(:rule)
    end
  end

end
