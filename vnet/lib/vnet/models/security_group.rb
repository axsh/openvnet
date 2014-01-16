# -*- coding: utf-8 -*-

module Vnet::Models
  class SecurityGroup < Base
    taggable 'sg'
    plugin :paranoia
    many_to_many :interfaces, :join_table => :interface_security_groups

    # We're using paranoia on the join table for the interface <=> security
    # group relation and that's throwing a wrench in Sequel's inner workings.
    # We override the relation accessors to remedy that.
    def interfaces
      interfaces_dataset.all
    end

    def interfaces_dataset
      join_ds = InterfaceSecurityGroup.where(
        security_group_id: self.id
      ).select(:interface_id)

      Interface.where(id: join_ds)
    end

    def interface_cookie_id(interface_id)
      row_id = InterfaceSecurityGroup.where(:security_group_id => self.id,
        :interface_id => interface_id).first.id

      #TODO: raise error when row not found

      InterfaceSecurityGroup.with_deleted.where(
        :security_group_id => self.id).where("id <= #{row_id}").count
    end
  end
end
