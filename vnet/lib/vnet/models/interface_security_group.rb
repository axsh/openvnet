# -*- coding: utf-8 -*-

module Vnet::Models
  class InterfaceSecurityGroup < Base
    plugin :paranoia

    many_to_one :interface
    many_to_one :security_group
  end
end
