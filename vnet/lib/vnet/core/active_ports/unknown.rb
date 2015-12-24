# -*- coding: utf-8 -*-

module Vnet::Core::ActivePorts

  class Unknown < Base

    def mode
      :unknown
    end

    def log_type
      'active_port/unknown'
    end

  end

end
