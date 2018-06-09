# -*- coding: utf-8 -*-

module Vnet::Core::Ports

  module Tunnel
    include Vnet::Openflow::FlowHelpers

    attr_accessor :underlay_port_number

    def log_type
      'port/tunnel'
    end

    def port_type
      :tunnel
    end

    def install
      @underlay_port_number = @dp_info.tunnel_manager.update(event: :set_tunnel_port_number,
                                                             port_name: self.port_name,
                                                             port_number: self.port_number)

      flows = []

      if @underlay_port_number && @underlay_port_number > 0
        flows << flow_create(table: TABLE_TUNNEL_PORTS,
                             goto_table: TABLE_TUNNEL_IDS,
                             priority: 30,

                             match: {
                               :in_port => self.port_number
                             },

                             write_value_pair_flag: true,
                             write_value_pair_first: 0,
                             write_value_pair_second: @underlay_port_number)
      end

      if @tunnel_id && @tunnel_id > 0
        flows << flow_create(table: TABLE_OUT_PORT_TUNNEL,
                             priority: 1,
                             match_tunnel: @tunnel_id,
                             actions: {
                               :output => self.port_number
                             })
        flows << flow_create(table: TABLE_OUT_PORT_TUNNEL,
                             priority: 2,

                             match_tunnel: @tunnel_id,
                             match_reflection: true,
                             match: {
                               :in_port => self.port_number
                             },
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
