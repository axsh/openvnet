# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class SecurityGroupInterface < Base
    plugin :paranoia_is_deleted

    many_to_one :interface
    many_to_one :security_group
  end

end
