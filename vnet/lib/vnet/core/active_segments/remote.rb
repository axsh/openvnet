# -*- coding: utf-8 -*-

module Vnet::Core::ActiveSegments

  class Remote < Base

    def mode
      :remote
    end

    def log_type
      'active_segment/remote'
    end

  end

end
