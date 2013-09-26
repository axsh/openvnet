# -*- coding: utf-8 -*-

module Vnet::Models
  class MacLease < Base
    taggable 'ml'

    plugin :mac_address

    many_to_one :interface

    def mac_addr
      self.mac_address.mac_address
    end
  end
end
