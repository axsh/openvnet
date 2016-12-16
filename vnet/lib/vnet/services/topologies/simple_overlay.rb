# -*- coding: utf-8 -*-

module Vnet::Services::Topologies

  class SimpleOverlay < Base
    include Celluloid::Logger

    def log_type
      'topology/simple_overlay'
    end

    [ [:network, :network_id],
      [:segment, :segment_id],
      [:route_link, :route_link_id]
    ].each { |other_name, other_key|

      define_method "create_dp_#{other_name}".to_sym do |params|
        other_id = get_param_id(params, other_key)
        datapath_id = get_param_id(params, :datapath_id)

        _, assoc_map = @datapaths.detect { |assoc_key, assoc_map|
          assoc_map[:datapath_id] == datapath_id
        }

        if assoc_map.nil?
          warn log_format_h("could not find topology_datapath for new datapath_#{other_name}", params)
          return
        end

        create_params = {
          datapath_id: datapath_id,
          other_key => other_id,

          lease_detection: {
            interface_id: assoc_map[:interface_id]
          }
        }

        create_datapath_other(other_name, create_params)
      end

    }

  end

end
