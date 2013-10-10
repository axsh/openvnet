# -*- coding: utf-8 -*-

module Vnet::Models
  class SecurityGroup < Base
    taggable 'sg'
    many_to_many :interfaces, :join_table => :interface_security_groups
    one_to_many :security_group_rules
  end
end
