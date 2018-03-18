# -*- coding: utf-8 -*-

# @underlay_datapaths:
# datapath_id
# interface_id
# ip_lease_id
# layer_id

module Vnet::Services::Topologies
  class SimpleOverlay < Base
    include Celluloid::Logger

    def initialize(params)
      super

      @underlay_datapaths = {}
    end    

    def log_type
      'topology/simple_overlay'
    end

    [ [:network, :network_id],
      [:segment, :segment_id],
      [:route_link, :route_link_id]
    ].each { |other_name, other_key|

      define_method "handle_added_#{other_name}".to_sym do |assoc_id, assoc_map|
        debug log_format_h("handle added #{other_name}", assoc_map)

        other_id = get_param_id(assoc_map, other_key)

        @underlay_datapaths.each { |tp_id, u_dp_list|
          debug log_format_h('trying underlay', u_dp_list)

          u_dp_list.each { |datapath_id, u_dp|
            create_params = {
              datapath_id: datapath_id,
              other_key => other_id,
              interface_id: u_dp[:interface_id],
              ip_lease_id: u_dp[:ip_lease_id],
              topology_layer_id: u_dp[:layer_id],
            }
            create_datapath_other(other_name, create_params)
          }
        }
      end

      define_method "handle_removed_#{other_name}".to_sym do |assoc_id, assoc_map|
        debug log_format_h("handle removed #{other_name}", assoc_map)

        delete_params = {
          topology_id: @id,
          other_key => get_param_id(assoc_map, other_key),
        }
        delete_datapath_other(other_name, delete_params)
      end

      define_method "updated_underlay_#{other_name}".to_sym do |datapath_id:, interface_id:, ip_lease_id:, layer_id:|
        other_list(other_name).each { |id, other_map|
          create_params = {
            datapath_id: datapath_id,
            other_key => other_map[other_key],
            interface_id: interface_id,
            ip_lease_id: ip_lease_id,
            topology_layer_id: layer_id,
          }

          # TODO: Don't log errors when already exists.
          create_datapath_other(other_name, create_params)
        }
      end

      define_method "updated_all_#{other_name}".to_sym do
        @underlay_datapaths.each { |u_tp_id, u_dp_list|
          u_dp_list.each { |datapath_id, u_dp_map|
            other_list(other_name).each { |_, other_map|
              create_params = {
                datapath_id: datapath_id,
                other_key => other_map[other_key],
                interface_id: u_dp_map[:interface_id],
                ip_lease_id: u_dp_map[:ip_lease_id],
                topology_layer_id: u_dp_map[:layer_id],
              }

              create_datapath_other(other_name, create_params)
            }
          }
        }
      end
    }

    def underlay_added_datapath(params)
      debug log_format_h('added underlay datapath', params)

      tp_id = get_param_id(params, :underlay_id)
      datapath_id = get_param_id(params, :datapath_id)

      (@underlay_datapaths[tp_id] ||= {}).tap { |u_dp_list|
        return if u_dp_list[datapath_id]

        u_dp = u_dp_list[datapath_id] = {
          datapath_id: datapath_id,
          interface_id: get_param_id(params, :interface_id),
          ip_lease_id: get_param_id(params, :ip_lease_id),
          layer_id: get_param_id(params, :layer_id),
        }

        updated_underlay_network(u_dp)
        updated_underlay_segment(u_dp)
        updated_underlay_route_link(u_dp)
      }
    end

    def underlay_removed_datapath(params)
      debug log_format_h('removed underlay datapath', params)

      @underlay_datapaths.delete(get_param_id(params, :underlay_id))

      delete_params = {
        topology_id: @id,
        topology_layer_id: get_param_id(params, :layer_id),
        datapath_id: get_param_id(params, :datapath_id),
      }
      delete_datapath_other(:network, delete_params)
      delete_datapath_other(:segment, delete_params)
      delete_datapath_other(:route_link, delete_params)
    end

    def handle_added_mac_range_group(assoc_id, assoc_map)
      debug log_format_h('handle added mac_range_group', assoc_map)

      # TODO: Print warning if the mrg has no range entries.

      updated_all_network()
      updated_all_segment()
      updated_all_route_link()
    end

    def handle_removed_mac_range_group(assoc_id, assoc_map)
      debug log_format_h('handle removed mac_range_group', assoc_map)

      # Make sure deleted dp_* are created if another mrg is available.
      updated_all_network()
      updated_all_segment()
      updated_all_route_link()
    end

    def handle_added_underlay(assoc_id, assoc_map)
      debug log_format_h('handle added underlay', assoc_map)

      # Do nothing, handled in underlay_added_datapath.
    end

    def handle_removed_underlay(assoc_id, assoc_map)
      debug log_format_h('handle removed underlay', assoc_map)

      # TODO: Remove underlay_datapath, no need for uninstall events.
    end

  end
end
