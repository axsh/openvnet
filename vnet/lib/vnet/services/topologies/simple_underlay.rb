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

      define_method "handle_added_#{other_name}".to_sym do |assoc_id, assoc_map|
        # other_id = get_param_id(assoc_map, other_key)
        # create_dp_other_each_active(other_name: other_name,
        #                             other_key: other_key,
        #                             other_id: other_id,
        #                             each_active_filter: { other_key => other_id }).tap { |dp_other|
        #   if dp_other.nil?
        #     debug log_format_h("failed to create datapath_#{other_name} for underlay", assoc_map)
        #     return
        #   end

        #   debug log_format_h("created datapath_#{other_name} for underlay", assoc_map)

        #   # TODO: Trigger update of overlays.
        # }
      end

      define_method "handle_removed_#{other_name}".to_sym do |assoc_id, assoc_map|
      end
    }

    # Simple_overlays's can create dp_rl's, while simple_underlays's
    # cannot. There is no such thing as an underlay route link.
    def handle_added_route_link(assoc_id, assoc_map)
      warn log_format_h("route_link is not supported on underlays", params)
    end
    alias :handle_removed_route_link :handle_added_route_link

    def handle_added_datapath(assoc_id, assoc_map)
      debug log_format_h('handle added datapath', assoc_map)

      u_dp = assoc_map.dup
      u_dp[:underlay_id] = @id

      @overlays.each { |overlay_id, overlay|
        u_dp[:id] = overlay_id

        @vnet_info.topology_manager.publish('topology_underlay_added_datapath', u_dp)
      }
    end

    def handle_removed_datapath(assoc_id, assoc_map)
      debug log_format_h('handle removed datapath', assoc_map)
    end

    def handle_added_overlay(assoc_id, assoc_map)
      debug log_format_h('handle added overlay', assoc_map)

      overlay_id = get_param_id(assoc_map, :overlay_id)

      @datapaths.each { |id, other_map|
        debug log_format_h('handle added overlay for datapath', other_map)

        u_dp = other_map.dup
        u_dp[:id] = overlay_id
        u_dp[:underlay_id] = @id

        @vnet_info.topology_manager.publish('topology_underlay_added_datapath', u_dp)
      }
    end

    def handle_removed_overlay(assoc_id, assoc_map)
      debug log_format_h('handle removed overlay', assoc_map)
    end

    # TODO: On uninstall, send underlay remove events.

  end
end
