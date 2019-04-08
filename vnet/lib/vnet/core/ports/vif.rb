# -*- coding: utf-8 -*-

module Vnet::Core::Ports

  module Vif
    include Vnet::Openflow::FlowHelpers

    def log_type
      'port/vif'
    end

    def port_type
      :vif
    end

    def cookie(tag = nil)
      value = self.port_number | COOKIE_TYPE_PORT
      tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    end

    def install
      flows = []
      flows << flow_create(table: TABLE_CLASSIFIER,
                           goto_table: TABLE_INTERFACE_EGRESS_CLASSIFIER_IF_NIL,
                           priority: 11,
                           
                           match: {
                             :in_port => self.port_number,
                           },
                           
                           write_value_pair_flag: FLAG_LOCAL,
                           write_value_pair_first: @interface_id,
                           write_value_pair_second: 0,
                           )
      flows << flow_create(table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 10,
                           match_interface: @interface_id,
                           actions: {
                             :output => self.port_number
                           })

      @dp_info.add_flows(flows)
    end

  end

end
