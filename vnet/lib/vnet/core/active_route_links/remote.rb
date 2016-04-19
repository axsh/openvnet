# -*- coding: utf-8 -*-

module Vnet::Core::ActiveRouteLinks

  class Remote < Base

    def mode
      :remote
    end

    def log_type
      'active_route_link/remote'
    end

  end

end
