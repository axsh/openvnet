# -*- coding: utf-8 -*-

module Vnet::Models
  class SecurityGroup < Base
    taggable 'sg'
    plugin :paranoia
    many_to_many :interfaces, :join_table => :interface_security_groups

    def interface_cookie_id(interface_id)
      row_id = InterfaceSecurityGroup.where(:security_group_id => self.id,
        :interface_id => interface_id).first.id

      #TODO: raise error when row not found

      InterfaceSecurityGroup.with_deleted.where(
        :security_group_id => self.id).where("id <= #{row_id}").count
    end

    def interface_cookie_ids
      {nowrap: true}.tap do |hash|
        interfaces.each { |i| hash[i.id] = interface_cookie_id(i.id) }
      end
    end
  end
end
