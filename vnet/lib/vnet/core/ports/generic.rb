# -*- coding: utf-8 -*-

module Vnet::Core::Ports
  module Generic
    include Vnet::Openflow::FlowHelpers

    def log_type
      'port/generic'
    end

    def port_type
      :generic
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []
      flows << Vnet::Openflow::Flow.create(TABLE_CLASSIFIER, 2, {
                            :in_port => self.port_number
                           }, nil, flow_options.merge({:goto_table => TABLE_EDGE_SRC}))
      @dp_info.add_flows(flows)
    end
  end
end
