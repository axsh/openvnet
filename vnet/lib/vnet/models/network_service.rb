# -*- coding: utf-8 -*-

module Vnet::Models
  class NetworkService < Base
    taggable 'ns'

    plugin :paranoia

    many_to_one :interface

    def validate
      # TODO: Use constants.
      validates_includes [
        "dhcp",
        "dns",
        "router",
      ], :type
    end
  end
end
