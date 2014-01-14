# -*- coding: utf-8 -*-

module Vnet::Models
  class NetworkService < Base
    taggable 'ns'

    many_to_one :interface

    subset(:alives, {})

    def validate
      validates_includes [
        "dhcp",
        "dns",
        "router",
      ], :type
    end
  end
end
