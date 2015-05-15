# -*- coding: utf-8 -*-

module Vnet::Constants::Network
  UUID_PREFIX   = 'nw'.freeze
  MODE_INTERNAL = 'internal'
  MODE_PHYSICAL = 'physical'
  MODE_VIRTUAL  = 'virtual'

  MODES = [MODE_INTERNAL,
           MODE_PHYSICAL,
           MODE_VIRTUAL]
end
