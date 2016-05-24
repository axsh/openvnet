# -*- coding: utf-8 -*-

module Vnet::Core::ActiveSegments

  class Local < Base

    def mode
      :local
    end

    def log_type
      'active_segment/local'
    end

  end

end
