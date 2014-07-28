# -*- coding: utf-8 -*-

module Vnet::Models

  class Translation < Base
    taggable 'tr'

    many_to_one :interface

    one_to_many :translation_static_addresses

    plugin :association_dependencies,
      :translation_static_addresses => :destroy

    subset(:alives, {})

  end

end
