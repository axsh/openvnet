# -*- coding: utf-8 -*-

module Vnet::Core::Ports

  module Promiscuous
    include Vnet::Openflow::FlowHelpers

    def log_type
      'port/promiscuous'
    end

    def port_type
      :promiscuous
    end

    def install
      return if @interface_id.nil?

      flows = []
      
      flow_match = { :in_port => port_number }

      flows << flow_create(table: TABLE_CLASSIFIER,
                           goto_table: TABLE_PROMISCUOUS_PORT,
                           priority: 2,
                           match: flow_match,
                           write_interface: @interface_id,
                           write_local: true)
      flows << flow_create(table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                           priority: 2,
                           match: flow_match,
                           match_interface: @interface_id,
                           match_reflection: true,
                           actions: {
                             :output => OFPP_IN_PORT
                           })
      flows << flow_create(table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                           priority: 1,
                           match_interface: @interface_id,
                           actions: {
                             :output => port_number
                           })

      @dp_info.add_flows(flows)
    end

    def uninstall
    end

    private

    # Currently only supports a single network or segment for each
    # interface and it is not safe to have more than one dp_nw/seg for
    # an interface.
    #
    # For now the dp_nw/seg will only work if it already exists when
    # the datapath is initialized, and has an ip_lease_id of nil.
    #
    # The dp_nw/seg idea seem not to be viable due to there only being
    # possible to have one dp+nw combination.
    #
    # Thus we should use the vna.conf file for tests until we add
    # interface_networks where an interface can be added to a network
    # without an ip_lease.

  end

end
