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

      #
      # IPv4 protocol codes
      # http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
      #

      IPV4_PROTOCOL_ICMP = 1
      IPV4_PROTOCOL_TCP  = 6
      IPV4_PROTOCOL_UDP  = 17

    end
  end
end
