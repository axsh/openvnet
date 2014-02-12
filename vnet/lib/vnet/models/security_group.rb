# -*- coding: utf-8 -*-

module Vnet::Models
  class SecurityGroup < Base
    taggable 'sg'
    plugin :paranoia
    many_to_many :interfaces, :join_table => :interface_security_groups

    # We're using paranoia on the join table for the interface <=> security
    # group relation and that's throwing a wrench in Sequel's inner workings.
    # We override the relation accessors to remedy that.
    def interfaces_dataset
      ds = Interface.join(:interface_security_groups, interface_id: :id)
      ds = ds.where(interface_security_groups__deleted_at: nil)
      ds.where(security_group_id: self.id).select_all(:interfaces)
    end

    # We override this method for the same reason
    def remove_interface(interface)
      InterfaceSecurityGroup.filter(
        interface_id: interface.id,
        security_group_id: id
      ).destroy
    end

    def interface_cookie_id(interface_id)
      row_id = InterfaceSecurityGroup.with_deleted.where(:security_group_id => self.id,
        :interface_id => interface_id).first.id

      #TODO: raise error when row not found

      InterfaceSecurityGroup.with_deleted.where(
        :security_group_id => self.id).where("id <= #{row_id}").count
    end

    def ip_addresses
      interfaces.map { |i|
        i.ip_leases.map { |il| il.ip_address.ipv4_address }
      }.flatten
    end
  end
end
