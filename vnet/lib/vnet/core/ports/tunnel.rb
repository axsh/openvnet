# -*- coding: utf-8 -*-

module Vnet::Core::Ports

  module Tunnel
    include Vnet::Openflow::FlowHelpers

    attr_accessor :underlay_interface_id

    def log_type
      'port/tunnel'
    end

    def port_type
      :tunnel
    end

    def install
      @underlay_interface_id = @dp_info.tunnel_manager.update(event: :set_tunnel_port_number,
                                                              port_name: self.port_name,
                                                              port_number: self.port_number)

      flows = []

      if @underlay_interface_id && @underlay_interface_id > 0
        flows << flow_create(table: TABLE_CLASSIFIER,
                             goto_table: TABLE_TUNNEL_IF_NIL,
                             priority: 30,

                             match: {
                               :in_port => self.port_number
                             },

                             write_reflection: false,
                             write_remote: true,
                             write_first: @underlay_interface_id,
                             write_second: 0,
                            )
      end

      if @tunnel_id && @tunnel_id > 0
        flows << flow_create(table: TABLE_OUT_PORT_EGRESS_TUN_NIL,
                             priority: 1,
                             
                             match_first: @tunnel_id,

                             actions: {
                               :output => self.port_number
                             })
        flows << flow_create(table: TABLE_OUT_PORT_EGRESS_TUN_NIL,
                             priority: 2,

                             match: {
                               :in_port => self.port_number
                             },
                             match_reflection: true,
                             match_first: @tunnel_id,

                             actions: {
                               :output => OFPP_IN_PORT
                             })
      end

      @dp_info.add_flows(flows)
    end

    def uninstall
      super
      @dp_info.tunnel_manager.update(event: :clear_tunnel_port_number,
                                     port_name: self.port_name)
    end

  end
end
