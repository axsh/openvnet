# -*- coding: utf-8 -*-

module Vnet::Models
  class SecurityGroup < Base
    taggable 'sg'
    many_to_many :interfaces, :join_table => :interface_security_groups

    def interface_cookie_id(interface_id)
      cookie_id = self.interfaces_dataset.where(
        "interfaces.id <= #{interface_id}").count

      raise "Interface '%s' isn't in security group '%s'" %
        [interface_id, self.canonical_uuid] if cookie_id == 0

      cookie_id
    end
  end
end
