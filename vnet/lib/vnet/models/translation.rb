# -*- coding: utf-8 -*-

module Vnet::Models

  class Translation < Base
    taggable 'tr'

    many_to_one :interface

    one_to_many :translate_static_addresses

    subset(:alives, {})

  end

end
