# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class NetworkService < Base
    taggable 'ns'

    plugin :paranoia_is_deleted

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
