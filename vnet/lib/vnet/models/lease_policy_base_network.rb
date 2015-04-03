# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class LeasePolicyBaseNetwork < Base

    many_to_one :lease_policy
    many_to_one :network
    many_to_one :ip_range_group

  end

end
