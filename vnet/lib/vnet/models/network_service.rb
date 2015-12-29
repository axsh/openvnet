# -*- coding: utf-8 -*-

module Vnet::Models
  class NetworkService < Base
    taggable 'ns'
    use_modes

    plugin :paranoia_is_deleted

    many_to_one :interface
    one_to_many :dns_services

    plugin :association_dependencies,
    # 0002_services
    dns_services: :destroy

    def valid_modes
      Vnet::Constants::NetworkService::MODES
    end

  end
end
