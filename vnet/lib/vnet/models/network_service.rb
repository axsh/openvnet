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

    # TODO: Rename type to mode, then add deprecation translation in
    # api.

    def valid_modes
      Vnet::Constants::NetworkService::MODES
    end

    def validate
      validates_includes(valid_modes, :mode)
      super
    end

  end
end
