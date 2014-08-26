# -*- coding: utf-8 -*-

module Vnet::Models
  class NetworkService < Base
    taggable 'ns'

    plugin :paranoia_is_deleted

    many_to_one :interface
    one_to_many :dns_services

    plugin :association_dependencies,
    # 0002_services
    dns_services: :destroy

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
