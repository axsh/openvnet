# -*- coding: utf-8 -*-

module Vnet::Core::ActiveNetworks

  class Local < Base

    def mode
      :local
    end

    def log_type
      'active_network/local'
    end

  end

end
