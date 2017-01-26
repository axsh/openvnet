# -*- coding: utf-8 -*-

module Vnet::Core::ActiveRouteLinks

  class Local < Base

    def mode
      :local
    end

    def log_type
      'active_route_link/local'
    end

  end

end
