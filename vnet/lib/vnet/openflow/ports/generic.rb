# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports
  module Generic
    include Vnet::Openflow::FlowHelpers

    def port_type
      :generic
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
    end
  end
end
