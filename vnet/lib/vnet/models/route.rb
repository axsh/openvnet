# -*- coding: utf-8 -*-

module Vnet::Models
  class Route < Base
    taggable 'r'

    many_to_one :vif
    many_to_one :route_link

    subset(:alives, {})

  end
end
