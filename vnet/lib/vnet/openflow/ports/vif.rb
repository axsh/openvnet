# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Vif
    include Vnet::Openflow::FlowHelpers

    attr_accessor :interface_id

    def port_type
      :vif
    end

    def cookie(tag = nil)
      value = self.port_number | COOKIE_TYPE_PORT
      tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    end

    def install
      flows = []
      flows << flow_create(:default,
                           table: TABLE_CLASSIFIER,
                           priority: 2,
                           match: {
                             :in_port => self.port_number,
                           },
                           write_interface: @interface_id,
                           write_local: true,
                           goto_table: TABLE_INTERFACE_CLASSIFIER)
      flows << flow_create(:default,
                           table: TABLE_OUTPUT_INTERFACE_INGRESS,
                           priority: 10,
                           match_interface: @interface_id,
                           actions: {
                             :output => self.port_number
                           })

      @dp_info.add_flows(flows)
    end

  end

end
