# -*- coding: utf-8 -*-

module Vnet::Services::Topologies

  class SimpleUnderlay < Base
    include Celluloid::Logger

    def log_type
      'topology/simple_underlay'
    end

    [ [:network, :network_id],
      [:segment, :segment_id]
    ].each { |other_name, other_key|

      define_method "create_dp_#{other_name}".to_sym do |params|
        other_id = get_param_id(params, other_key)
        datapath_id = get_param_id(params, :datapath_id)

        # This should instead search for an interface on network_id.
        interface_id = get_a_host_interface_id(datapath_id)

        if interface_id.nil?
          warn log_format_h("could not find host interface for new datapath_#{other_name}", params)
          return
        end

        # Verify that the interface is on the network/segment and pass along the
        # ip_lease.

        create_params = {
          datapath_id: datapath_id,
          other_key => other_id,
          interface_id: interface_id,
          # disable_lease_detection: true
        }

        create_datapath_other(other_name, create_params)
      end

    }

    # Simple_overlays's can create dp_rl's, while simple_underlays's
    # cannot. There is no such thing as an underlay route link.
    def create_dp_route_link(params)
      warn log_format_h("route links are not supported on underlays", params)
    end

  end

end
