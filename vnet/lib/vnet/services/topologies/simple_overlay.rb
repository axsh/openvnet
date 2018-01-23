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

      define_method "handle_added_#{other_name}".to_sym do |assoc_id, assoc_map|
        debug log_format_h('handle added #{other_name}', assoc_map)

        other_id = get_param_id(assoc_map, other_key)

        @underlays.each { |id, underlay|
          debug log_format_h('trying underlay', underlay)

          # TODO: Move to node_api.
          underlay[:datapaths].each { |_, datapath|
            create_params = {
              datapath_id: datapath[:datapath_id],
              other_key => datapath[other_key],
              ip_lease_id: datapath[:ip_lease_id],
            }
            create_datapath_other(other_name, create_params)
          }
        }
      end

      define_method "handle_removed_#{other_name}".to_sym do |assoc_id, assoc_map|
      end

      define_method "updated_underlay_#{other_name}".to_sym do |datapath_id:, other_id:, ip_lease_id:|
        create_params = {
          datapath_id: datapath_id,
          other_key => other_id,
          ip_lease_id: ip_lease_id,
        }

        # TODO: Don't log errors(?).
        create_datapath_other(other_name, create_params)
      end
    }

    def handle_added_datapath(assoc_id, assoc_map)
      debug log_format_h('handle added datapath', assoc_map)
    end

    def handle_removed_datapath(assoc_id, assoc_map)
      debug log_format_h('handle removed datapath', assoc_map)
    end

    def added_underlay_datapath(params)
      debug log_format_h('added underlay datapath', params)

      @underlays[get_param_id(params, :underlay_id)].tap { |tp_dp|
        if tp_dp.nil?
          debug log_format_h("no underlay found when adding updating underlay datapath", params)
          next
        end

        tp_dp[:datapaths].tap { |datapaths|
          tp_id = get_param_id(params, :id)
          next if datapaths[tp_id]

          dp = datapaths[tp_id] = {
            datapath_id: get_param_id(params, :datapath_id),
            interface_id: get_param_id(params, :interface_id),
            ip_lease_id: get_param_id(params, :ip_lease_id),
          }

          updated_underlay_network(datapath_id, interface_id, ip_lease_id)
          # more...
        }
      }
    end

    def removed_underlay_datapath(params)
      debug log_format_h('removed underlay datapath', params)
    end

  end
end
