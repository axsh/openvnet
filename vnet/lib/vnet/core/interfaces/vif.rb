# -*- coding: utf-8 -*-

module Vnet::Core::Interfaces

  class Vif < IfBase

    def log_type
      'interface/vif'
    end

    def add_mac_address(params)
      mac_info = super || return

      flows = []
      flows_for_interface_mac(flows, mac_info)
      flows_for_mac2mac_mac(flows, mac_info)

      if @enable_routing
        flows_for_router_ingress_mac(flows, mac_info)
        flows_for_router_egress_mac(flows, mac_info)
      end

      @dp_info.add_flows(flows)
    end

    def add_ipv4_address(params)
      mac_info, ipv4_info = super || return

      @dp_info.network_manager.insert_interface_network(@id, ipv4_info[:network_id])

      flows = []
      flows_for_ipv4(flows, mac_info, ipv4_info)
      flows_for_interface_ipv4(flows, mac_info, ipv4_info)
      flows_for_mac2mac_ipv4(flows, mac_info, ipv4_info)

      if @enable_routing
        flows_for_router_ingress_ipv4(flows, mac_info, ipv4_info)
        flows_for_router_ingress_mac2mac_ipv4(flows, mac_info, ipv4_info)
        flows_for_router_egress_ipv4(flows, mac_info, ipv4_info)
      end

      @dp_info.add_flows(flows)
    end

    def remove_ipv4_address(params)
      mac_info, ipv4_info = super || return

      return unless ipv4_info

      @dp_info.network_manager.remove_interface_network(@id, ipv4_info[:network_id])
    end

    def install
      flows = []
      flows_for_disabled_filtering(flows) unless @enabled_filtering || @enabled_legacy_filtering
      flows_for_disabled_legacy_filtering(flows) unless @ingress_filtering_enabled || !@enabled_legacy_filtering
      flows_for_base(flows)
      flows_for_classifiers(flows)

      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_base(flows)
    end

    def flows_for_mac(flows, mac_info)
    end

    def flows_for_ipv4(flows, mac_info, ipv4_info)
    end

  end

end
