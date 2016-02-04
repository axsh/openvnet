# -*- coding: utf-8 -*-

module Vnet::Core::ActiveNetworks

  class Remote < Base

    def mode
      :remote
    end

    def log_type
      'active_network/remote'
    end

  end

end
