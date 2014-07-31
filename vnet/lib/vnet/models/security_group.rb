# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class SecurityGroup < Base
    include Vnet::Helpers::SecurityGroup

    taggable 'sg'

    plugin :paranoia

    one_to_many :security_group_interfaces
    many_to_many :interfaces, :join_table => :security_group_interfaces

    # We're using paranoia on the join table for the interface <=> security
    # group relation and that's throwing a wrench in Sequel's inner workings.
    # We override the relation accessors to remedy that.
    def interfaces_dataset
      ds = Interface.join(:security_group_interfaces, interface_id: :id)
      ds = ds.where(security_group_interfaces__deleted_at: nil)
      ds.where(security_group_id: self.id).select_all(:interfaces)
    end

    # We override this method for the same reason
    def remove_interface(interface)
      SecurityGroupInterface.filter(
        interface_id: interface.id,
        security_group_id: id
      ).destroy
    end

    def interface_cookie_id(interface_id)
      row_id = SecurityGroupInterface.with_deleted.where(:security_group_id => self.id,
        :interface_id => interface_id).first.id

      SecurityGroupInterface.with_deleted.where(
        :security_group_id => self.id).where("id <= #{row_id}").count
    end

    def ip_addresses
      interfaces.map { |i|
        i.ip_leases.map { |il| il.ip_address.ipv4_address }
      }.flatten
    end

    def validate
      rules && split_rule_collection(rules).each { |r|
        valid, error_msg = validate_rule(r)
        errors.add(error_msg, "'#{r}'") unless valid

        if is_reference_rule?(r)
          self.class[split_rule(r)[2]] ||
            errors.add("Unknown security group uuid in rule", "'#{r}'")
        end
      }
    end
  end
end
