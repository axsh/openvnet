# -*- coding: utf-8 -*-

module Vnet::Models
  class MacLease < Base
    taggable 'ml'

    many_to_one :interface
  end
end
