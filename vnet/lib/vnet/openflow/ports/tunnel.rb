# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Tunnel
    include Vnet::Openflow::FlowHelpers

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
      flows << flow_create(:default,
                           table: TABLE_VIRTUAL_SRC,
                           priority: 30,
                           match: {
                             :in_port => self.port_number
                           },
                           goto_table: TABLE_ROUTER_CLASSIFIER)
      flows << flow_create(:default,
                           table: TABLE_OUTPUT_DATAPATH,
                           priority: 5,
                           match_metadata: {
                             :datapath => @dst_id,
                             :tunnel => nil
                           },
                           actions: {
                             :output => self.port_number
                           })

      @dp_info.add_flows(flows)
      @dp_info.tunnel_manager.update_item(event: :set_port_number,
                                          port_name: self.port_name,
                                          port_number: self.port_number)
    end

    def uninstall
      @dp_info.tunnel_manager.update_item(event: :clear_port_number,
                                          port_name: self.port_name)
    end

  end
end
