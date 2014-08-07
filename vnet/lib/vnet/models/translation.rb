# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class Translation < Base
    taggable 'tr'

    plugin :paranoia

    many_to_one :interface

    one_to_many :translation_static_addresses

    plugin :association_dependencies,
      :translation_static_addresses => :destroy

  end

end
