# -*- coding: utf-8 -*-

module Vnet::Core::Ports

  module Local
    include Vnet::Openflow::FlowHelpers

    def log_type
      'port/local'
    end

    def port_type
      :local
    end

  end

end
