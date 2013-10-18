# -*- coding: utf-8 -*-

module Vnet::Openflow
  class TranslationManager < Manager
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Dispatchable

    def initialize(dp_info)
      @dp_info = dp_info
      @dpid_s = "0x%016x" % @dp_info.dpid

      @dp_info.packet_manager.insert(VnetEdge::TranslationHandler.new(dp_info: @dp_info), nil, (COOKIE_PREFIX_TRANSLATION << COOKIE_PREFIX_SHIFT))

      @edge_ports = []

      update_translation_map
    end

    def add_edge_port(params)
      @edge_ports << {
        :port => params[:port],
        :interface => params[:interface],
        :vlan_vs_mac_address => []
      }
    end

    def network_to_vlan(network_id)
      entry = @translation_map.find { |t| t.network_id == network_id }
      return nil if entry.nil?
      entry.vlan_id
    end

    def vlan_to_network(vlan_vid)
      entry = @translation_map.find { |t| t.vlan_id == vlan_vid }
      entry.network_id
    end

    private

    def log_format(message, values = nil)
      "#{@dpid_s} translation_manager: #{message}" + (values ? " (#{values})" : '')
    end

    def update_translation_map
      @translation_map = Vnet::ModelWrappers::VlanTranslation.batch.all.commit
    end
  end

end
