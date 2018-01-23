# -*- coding: utf-8 -*-

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
            }
            create_datapath_other(other_name, create_params)
          }
        }
      end

      define_method "handle_removed_#{other_name}".to_sym do |assoc_id, assoc_map|
      end

      define_method "updated_underlay_#{other_name}".to_sym do |datapath_id:, interface_id:, ip_lease_id:|
        other_list(other_name).each { |id, other_map|
          create_params = {
            datapath_id: datapath_id,
            other_key => other_map[other_key],
            interface_id: interface_id,
            ip_lease_id: ip_lease_id,
          }

          # TODO: Don't log errors when already exists.
          create_datapath_other(other_name, create_params)
        }
      end
    }

    def handle_added_underlay(assoc_id, assoc_map)
      debug log_format_h('handle added underlay', assoc_map)
    end

    def handle_removed_underlay(assoc_id, assoc_map)
      debug log_format_h('handle removed underlay', assoc_map)

      # TODO: Remove underlay_datapath, no need for uninstall events.
    end

    def underlay_added_datapath(params)
      debug log_format_h('added underlay datapath', params)

      tp_id = get_param_id(params, :id)
      datapath_id = get_param_id(params, :datapath_id)

      (@underlay_datapaths[tp_id] ||= {}).tap { |u_dp_list|
        return if u_dp_list[datapath_id]

        u_dp = u_dp_list[datapath_id] = {
          datapath_id: datapath_id,
          interface_id: get_param_id(params, :interface_id),
          ip_lease_id: get_param_id(params, :ip_lease_id),
        } 

        updated_underlay_network(u_dp)
        updated_underlay_segment(u_dp)
        updated_underlay_route_link(u_dp)
      }
    end

    def underlay_removed_datapath(params)
      debug log_format_h('removed underlay datapath', params)
    end

  end
end
