# -*- coding: utf-8 -*-

module Vnet::Services::Topologies

  class SimpleUnderlay < Base
    include Celluloid::Logger

    def log_type
      'topology/simple_underlay'
    end

    def create_dp_nw(params)
      network_id = get_param_id(params, :network_id)
      datapath_id = get_param_id(params, :datapath_id)

      # This should instead search for an interface on network_id.
      interface_id = get_a_host_interface_id(datapath_id)

      if interface_id.nil?
        warn log_format_h("could not find host interface for new datapath_network", params)
        return
      end

      # Verify that the interface is on the network and pass along the
      # ip_lease.

      create_datapath_network(datapath_id, network_id, interface_id)
    end

    def create_dp_rl(params)
      route_link_id = get_param_id(params, :route_link_id)
      datapath_id = get_param_id(params, :datapath_id)

      # This should instead search for an interface on route_link_id.
      interface_id = get_a_host_interface_id(datapath_id)

      if interface_id.nil?
        warn log_format_h("could not find host interface for new datapath_route_link", params)
        return
      end

      # Verify that the interface is on the route link and pass along the
      # ip_lease.

      create_datapath_route_link(datapath_id, route_link_id, interface_id)
    end

  end

end
