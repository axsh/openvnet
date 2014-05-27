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
      set_remote_md = flow_options.merge(md_create(:remote => nil))

      reflection_md = md_create(:reflection => nil)
      reflection_mac2mac_md = md_create({ :reflection => nil,
                                          :mac2mac => nil
                                        })

      flows = []

      if @interface_id
        flows << flow_create(table: TABLE_CLASSIFIER,
                             goto_table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
                             priority: 2,

                             match: {
                               :in_port => self.port_number
                             },

                             write_interface: @interface_id,
                             write_remote: true)

        flows << flow_create(table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                             priority: 2,
                             match: {
                               :in_port => self.port_number
                             },
                             match_interface: @interface_id,
                             match_reflection: true,
                             actions: {
                               :output => OFPP_IN_PORT
                             })
        flows << flow_create(table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                             priority: 1,
                             match_interface: @interface_id,
                             actions: {
                               :output => self.port_number
                             })
      end

      if @dp_info.datapath.datapath_info.node_id =~ /^edge/
        flows << flow_create(table: TABLE_CLASSIFIER,
                             goto_table: TABLE_EDGE_SRC,
                             priority: 2,
                             match: {
                               :in_port => self.port_number
                             },
                             write_remote: true)
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
