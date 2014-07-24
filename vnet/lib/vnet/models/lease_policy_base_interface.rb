# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class LeasePolicyBaseInterface < Base

    many_to_one :lease_policy
    many_to_one :interface

  end

end
