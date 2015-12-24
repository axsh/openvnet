# -*- coding: utf-8 -*-

module Vnet::Core::ActivePorts

  class Tunnel < Base

    def mode
      :tunnel
    end

    def log_type
      'active_port/tunnel'
    end

  end

end
