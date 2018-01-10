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

        return if create_dp_other(datapath_id: datapath_id, other_name: other_name, other_key: other_key, other_id: other_id)

        debug log_format_h("could not create topology_datapath for new datapath_#{other_name}", params)

        underlay_params = {
          id: nil,
          datapath_id: datapath_id,
          other_name: other_name,
          other_key: other_key,
          other_id: other_id
        }

        @underlays.each { |id, underlay|
          debug log_format_h('trying underlay', underlay)

          underlay_params[:id] = underlay[:underlay_id]

          @vnet_info.topology_manager.publish('topology_underlay_create', underlay_params)
        }
      end

      define_method "handle_added_#{other_name}".to_sym do |assoc_id, assoc_map|
      end

      define_method "handle_removed_#{other_name}".to_sym do |assoc_id, assoc_map|
      end

    }

  end
end
