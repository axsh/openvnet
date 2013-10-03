# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Tunnel
    include Vnet::Openflow::FlowHelpers

    def port_type
      :tunnel
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []
      flows << Flow.create(TABLE_TUNNEL_PORTS, 30, {
                             :in_port => self.port_number
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_TUNNEL_NETWORK_IDS))
      flows << Flow.create(TABLE_VIRTUAL_SRC, 30, {
                             :in_port => self.port_number
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_CLASSIFIER))

      @dp_info.add_flows(flows)
      @dp_info.tunnel_manager.add_port(self)
    end

    def uninstall
      @dp_info.tunnel_manager.del_port(self)
      super
    end

  end
end
