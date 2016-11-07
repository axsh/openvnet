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

        interface_id = get_a_host_interface_id(datapath_id)

        if interface_id.nil?
          warn log_format_h("could not find host interface for new datapath_#{other_name}", params)
          return
        end

        create_datapath_other(other_name, datapath_id, other_id, interface_id)
      end

    }

  end

end
