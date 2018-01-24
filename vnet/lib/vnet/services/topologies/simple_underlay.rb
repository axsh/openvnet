# -*- coding: utf-8 -*-

# Adding ip leases is only required for topology datapaths when GRE
# tunnels are used. (or should be)
#
# The mac_range_group needs to have valid ranges when added, as we
# currently don't support events for adding/removing ranges.

# TODO: Need to properly handle events for changing of topology
# datapath's ip_leases.


module Vnet::Services::Topologies
  class SimpleUnderlay < Base
    include Celluloid::Logger

    def log_type
      'topology/simple_underlay'
    end

    [ [:network, :network_id],
      [:segment, :segment_id],
    ].each { |other_name, other_key|

      define_method "handle_added_#{other_name}".to_sym do |assoc_id, assoc_map|
        debug log_format_h("handle added #{other_name}", assoc_map)

        other_id = get_param_id(assoc_map, other_key)

        @datapaths.each { |tp_id, dp|
          debug log_format_h('trying datapath', dp)

          create_params = {
            datapath_id: dp[:datapath_id],
            other_key => other_id,
            interface_id: dp[:interface_id],
            ip_lease_id: dp[:ip_lease_id],
          }
          create_datapath_other(other_name, create_params)
        }
      end

      define_method "handle_removed_#{other_name}".to_sym do |assoc_id, assoc_map|
      end

      define_method "updated_datapath_#{other_name}".to_sym do |datapath_id:, interface_id:, ip_lease_id:|
        other_list(other_name).each { |id, other_map|
          create_params = {
            datapath_id: datapath_id,
            other_key => other_map[other_key],
            interface_id: interface_id,
            ip_lease_id: ip_lease_id,
          }

          create_datapath_other(other_name, create_params)
        }
      end

      define_method "updated_all_#{other_name}".to_sym do
        @datapaths.each { |_, datapath_map|
          other_list(other_name).each { |_, other_map|
            create_params = {
              datapath_id: datapath_map[:datapath_id],
              other_key => other_map[other_key],
              interface_id: datapath_map[:interface_id],
              ip_lease_id: datapath_map[:ip_lease_id],
            }

            create_datapath_other(other_name, create_params)
          }
        }
      end
    }

    def handle_added_datapath(assoc_id, assoc_map)
      debug log_format_h('handle added datapath', assoc_map)

      updated_datapath_network(assoc_map)
      updated_datapath_segment(assoc_map)

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

    def handle_added_mac_range_group(assoc_id, assoc_map)
      debug log_format_h('handle added mac_range_group', assoc_map)

      # TODO: Print warning if the mrg has no range entries.

      updated_all_network()
      updated_all_segment()
    end

    def handle_removed_mac_range_group(assoc_id, assoc_map)
      debug log_format_h('handle removed mac_range_group', assoc_map)

      updated_all_network()
      updated_all_segment()
    end

    def handle_added_overlay(assoc_id, assoc_map)
      debug log_format_h('handle added overlay', assoc_map)

      overlay_id = get_param_id(assoc_map, :overlay_id)

      @datapaths.each { |id, other_map|
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
