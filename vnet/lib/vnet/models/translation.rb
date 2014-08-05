# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class Translation < Base
    taggable 'tr'

    plugin :paranoia_is_deleted

    many_to_one :interface

    one_to_many :translation_static_addresses

    plugin :association_dependencies,
      :translation_static_addresses => :destroy

  end

end
