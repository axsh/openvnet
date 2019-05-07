# -*- coding: utf-8 -*-

module Vnet::Core::Ports

  module Host
    include Vnet::Openflow::FlowHelpers

    def log_type
      'port/host'
    end

    def port_type
      :host
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []

      if @interface_id
        flows << flow_create(table: TABLE_CLASSIFIER,
                             goto_table: TABLE_INTERFACE_INGRESS_CLASSIFIER_IF_NIL,
                             priority: 11,

                             match: {
                               :in_port => self.port_number
                             },

                             write_reflection: false,
                             write_remote: true,
                             write_first: @interface_id,
                             write_second: 0,
                            )

        flows << flow_create(table: TABLE_OUT_PORT_EGRESS_IF_NIL,
                             priority: 2,
                             
                             match: {
                               :in_port => self.port_number
                             },
                             match_reflection: true,
                             match_first: @interface_id,

                             actions: {
                               :output => OFPP_IN_PORT
                             })
        flows << flow_create(table: TABLE_OUT_PORT_EGRESS_IF_NIL,
                             priority: 1,
                             
                             match_first: @interface_id,

                             actions: {
                               :output => self.port_number
                             })
      end

      @dp_info.add_flows(flows)
      @dp_info.tunnel_manager.async.update(event: :updated_interface,
                                           interface_event: :set_host_port_number,
                                           interface_id: @interface_id,
                                           port_number: self.port_number)
    end

    def uninstall
      @dp_info.tunnel_manager.async.update(event: :updated_interface,
                                           interface_event: :set_host_port_number,
                                           interface_id: @id,
                                           port_number: nil)
    end

  end

end
