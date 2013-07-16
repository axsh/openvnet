# -*- coding: utf-8 -*-

module Vnet::Models
  class RouteLink < Base
    taggable 'rl'

    one_to_many :routes

    subset(:alives, {})

  end
end
