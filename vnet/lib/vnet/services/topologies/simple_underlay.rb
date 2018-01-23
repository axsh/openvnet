# -*- coding: utf-8 -*-

module Vnet::Services::Topologies
  class SimpleUnderlay < Base
    include Celluloid::Logger

    def log_type
      'topology/simple_underlay'
    end

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

  end
end
