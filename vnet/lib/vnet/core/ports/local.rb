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

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []
      flows << flow_create(table: TABLE_CLASSIFIER,
                           goto_table: TABLE_LOCAL_PORT,
                           priority: 2,
                           match: {
                             :in_port => OFPP_LOCAL
                           },
                           write_local: true)

      @dp_info.add_flows(flows)
    end

  end

end
