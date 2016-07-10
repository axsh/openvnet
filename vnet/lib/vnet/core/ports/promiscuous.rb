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

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []

      if @interface_id
        flows << flow_create(table: TABLE_CLASSIFIER,
                             goto_table: TABLE_PROMISCUOUS_PORT,
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

        prepare_dp_nw(flows)
      end

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

    def prepare_dp_nw(flows)
      # filter = {
      #   datapath_id: get_datapath_id,
      #   interface_id: @interface_id,
      #   ip_lease_id: nil
      # }

      # if filter[:datapath_id].nil?
      #   warn log_format('could not determine datapath_id')
      #   return
      # end

      # dp_nw = Vnet::ModelWrappers::DatapathNetwork.batch.dataset.where(filter).first.commit

      # if dp_nw.nil?
      #   warn log_format('could not find a valid datapath_network')
      #   return
      # end

      # Work-around until we have a way to add/remove interfaces to
      # networks/segments without creating ip/mac_leases. This would
      # be part of the active_network/segment managers.

      # !!! HARDCODE THESE VALUES.

      # dp_nw_cookie = dp_nw[:id] | COOKIE_TYPE_DP_NETWORK
      # network_id = dp_nw[:network_id]

      dp_nw_cookie = 2 | COOKIE_TYPE_NETWORK
      network_id = 2

      flows << flow_create(table: TABLE_PROMISCUOUS_PORT,
                           goto_table: TABLE_NETWORK_CONNECTION,
                           priority: 10,

                           match_interface: @interface_id,
                           write_network: network_id,

                           cookie: dp_nw_cookie)
      
      # Activate network?
      @dp_info.network_manager.retrieve(id: network_id)

      # Add to... FLOOD_LOCAL
      @dp_info.network_manager.insert_interface_network(@interface_id, network_id)
    end

    def get_datapath_id
      # TODO: Add a method to dp_info that caches datapath_info.
      datapath_info = @dp_info.datapath && @dp_info.datapath.datapath_info
      datapath_info.id
    end

  end

end
