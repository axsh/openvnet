# -*- coding: utf-8 -*-

require 'ipaddr'
require 'trema/mac'

module Vnet
  module Constants
    module Openflow

      include OpenflowFlows

      MW = Vnet::ModelWrappers

      #
      # Trema related constants:
      #

      MAC_ZERO       = Trema::Mac.new('00:00:00:00:00:00')
      MAC_BROADCAST  = Trema::Mac.new('ff:ff:ff:ff:ff:ff')
      IPV4_ZERO      = IPAddr.new('0.0.0.0')
      IPV4_BROADCAST = IPAddr.new('255.255.255.255')

    end
  end
end
