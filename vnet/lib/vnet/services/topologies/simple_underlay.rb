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

        create_params = {
          datapath_id: datapath_id,
          other_key => other_id,

          lease_detection: {
            other_key => other_id
          }
        }

        create_datapath_other(other_name, create_params).tap { |dp_other|
          if dp_other.nil?
            warn log_format_h("failed when creating new datapath_#{other_name}", create_params)
          end
        }
      end

    }

    # Simple_overlays's can create dp_rl's, while simple_underlays's
    # cannot. There is no such thing as an underlay route link.
    def create_dp_route_link(params)
      warn log_format_h("route_link is not supported on underlays", params)
    end

  end

end
