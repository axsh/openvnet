# -*- coding: utf-8 -*-

module Vnet::Core::ActivePorts

  class Local < Base

    def mode
      :local
    end

    def log_type
      'active_port/local'
    end

  end

end
