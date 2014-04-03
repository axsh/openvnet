# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Tunnel
    include Vnet::Openflow::FlowHelpers

    def log_type
      'port/tunnel'
    end

    def port_type
      :tunnel
    end

    def install
      flows = []
      flows << flow_create(:default,
                           table: TABLE_TUNNEL_PORTS,
                           priority: 30,
                           match: {
                             :in_port => self.port_number
                           },
                           goto_table: TABLE_TUNNEL_NETWORK_IDS)

      if @tunnel_id && @tunnel_id > 0
        flows << flow_create(:default,
                             table: TABLE_OUT_PORT_TUNNEL,
                             priority: 1,
                             match_tunnel: @tunnel_id,
                             actions: {
                               :output => self.port_number
                             })
        flows << flow_create(:default,
                             table: TABLE_OUT_PORT_TUNNEL,
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

      @dp_info.tunnel_manager.update(event: :set_tunnel_port_number,
                                     port_name: self.port_name,
                                     port_number: self.port_number)
    end

    def uninstall
      super
      @dp_info.tunnel_manager.update(event: :clear_tunnel_port_number,
                                     port_name: self.port_name,
                                     dynamic_load: false)
    end

  end
end
