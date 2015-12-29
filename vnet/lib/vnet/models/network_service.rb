# -*- coding: utf-8 -*-

module Vnet::Models
  class NetworkService < Base
    taggable 'ns'
    plugin :paranoia_is_deleted

    use_modes Vnet::Constants::NetworkService::MODES

    many_to_one :interface
    one_to_many :dns_services

    plugin :association_dependencies,
    # 0002_services
    dns_services: :destroy

  end
end
