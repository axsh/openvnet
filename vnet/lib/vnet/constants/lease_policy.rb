# -*- coding: utf-8 -*-

module Vnet::Constants
  module LeasePolicy
    ALLOCATION_TYPE_INCREMENTAL="incremental"
    ALLOCATION_TYPE_DECREMENTAL="decremental"
    ALLOCATION_TYPE_RANDOM="random"

    ALLOCATION_TYPES = [
      ALLOCATION_TYPE_INCREMENTAL,
      ALLOCATION_TYPE_DECREMENTAL,
      ALLOCATION_TYPE_RANDOM
    ]


    MODE_SIMPLE = "simple"
    MODES = [ MODE_SIMPLE ]

    TIMING_IMMEDIATE = "immediate"
    TIMING_DHCP = "dhcp"
    TIMINGS = [ TIMING_IMMEDIATE, TIMING_DHCP ]
  end
end
