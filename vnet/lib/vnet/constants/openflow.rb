# -*- coding: utf-8 -*-

require 'ipaddr'

# Remove top-level :array and :string methods introduced by trema-edge
# to avoid the conflict with BinData's primitive methods.
Class.class_eval { undef_method :array } rescue NameError
Class.class_eval { undef_method :string } rescue NameError
require 'pio'

module Vnet
  module Constants
    module Openflow

      include OpenflowFlows

      MW = Vnet::ModelWrappers

      #
      # Trema related constants:
      #

      MAC_ZERO       = Pio::Mac.new('00:00:00:00:00:00')
      MAC_BROADCAST  = Pio::Mac.new('ff:ff:ff:ff:ff:ff')
      IPV4_ZERO      = IPAddr.new('0.0.0.0')
      IPV4_BROADCAST = IPAddr.new('255.255.255.255')

      #
      # eth types
      #

      ETH_TYPE_IPV4 = 0x0800
      ETH_TYPE_ARP  = 0x0806

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
