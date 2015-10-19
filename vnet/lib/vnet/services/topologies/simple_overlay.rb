# -*- coding: utf-8 -*-

module Vnet::Services::Topologies

  class SimpleOverlay < Base
    include Celluloid::Logger

    def log_type
      'topology/simple_overlay'
    end

  end

end
