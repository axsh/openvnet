# -*- coding: utf-8 -*-

module Vnet::Core::Interfaces

  # Remote interface types are any type of interface that is located
  # on other datapaths.

  class Remote < Base

    def initialize(params)
      super

      @remote_mode = @mode
      @mode = :remote
    end

    def log_type
      'interface/remote'
    end

    def enable_router_egress
      return if @router_egress != false
      @router_egress = true
    end

    def disable_router_egress
      # Not supported atm.
    end

  end

end
