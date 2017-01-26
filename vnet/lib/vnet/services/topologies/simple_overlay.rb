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

        return if internal_create_dp_other(datapath_id: datapath_id, other_name: other_name, other_key: other_key, other_id: other_id)

        debug log_format_h("could not create topology_datapath for new datapath_#{other_name}", params)

        @underlays.each { |id, underlay|
          debug log_format_h('trying underlay', underlay)

          # We should 
        }
      end

    }

    private

    def internal_create_dp_other(datapath_id:, other_name:, other_key:, other_id:)
      assoc_map = find_datapath_assoc_map(datapath_id: datapath_id)

      if assoc_map.nil?
        return
      end

      create_params = {
        datapath_id: datapath_id,
        other_key => other_id,

        lease_detection: {
          interface_id: get_param_id(assoc_map, :interface_id)
        }
      }

      create_datapath_other(other_name, create_params)
    end

    def find_datapath_assoc_map(datapath_id:)
      _, assoc_map = @datapaths.detect { |assoc_key, assoc_map|
        assoc_map[:datapath_id] == datapath_id
      }

      assoc_map
    end

  end
end
