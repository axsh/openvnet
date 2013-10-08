# -*- coding: utf-8 -*-

module Vnet::Models
  class SecurityGroupRule < Base
    many_to_one :security_groups
  end
end
