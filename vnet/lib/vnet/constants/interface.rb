# -*- coding: utf-8 -*-

module Vnet::Constants::Interface
  MODE_HOST      = 'host'
  MODE_INTERNAL  = 'internal'
  MODE_PATCH     = 'patch'
  MODE_PROMISCUOUS = 'promiscuous'
  MODE_REMOTE    = 'remote'
  MODE_SIMULATED = 'simulated'
  MODE_VIF       = 'vif'

  MODES = [MODE_HOST,
           MODE_INTERNAL,
           MODE_PATCH,
           MODE_PROMISCUOUS,
           MODE_REMOTE,
           MODE_SIMULATED,
           MODE_VIF,
          ]
end
