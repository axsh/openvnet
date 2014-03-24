# -*- coding: utf-8 -*-

module Vnet::Models

  class LeasePolicyBaseNetwork < Base

    many_to_one :lease_policy
    many_to_one :network

    subset(:alives, {})  # TODO, understand this

  end

end
