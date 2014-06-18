# -*- coding: utf-8 -*-

module Vnet::Core::ActiveInterfaces

  class Local < Base

    def mode
      :local
    end

    def log_type
      'active_interface/local'
    end

  end

end
