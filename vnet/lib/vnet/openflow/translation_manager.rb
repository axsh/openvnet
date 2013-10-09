# -*- coding: utf-8 -*-

module Vnet::Openflow
  class TranslationManager < Manager
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Dispatchable

    def initialize(dp)
      @datapath = dp
      @dpid_s = "0x%016x" % @datapath.dpid

      @datapath.packet_manager.insert(VnetEdge::TranslationHandler.new(datapath: @datapath), nil, (COOKIE_PREFIX_VNETEDGE << COOKIE_PREFIX_SHIFT))

      @edge_ports = []

      update_translation_map

      info log_format('initialized')
    end

    def add_edge_port(port)
      @edge_ports << port
      info log_format('edge port added', port.inspect)
    end

    def find_edge_port(port_number)
      @edge_port.detect { |e| e[:port_number] == port_number }
    end

    def find_network_id(edge_port_id, vlan_vid)
      vt_entry = @translation_map.detect {|t| t.interface_id == edge_port_id && t.vlan_id == vlan_vid }

      error log_format('entry not found in vlan_translations table') if vt_entry.nil?

      vt.entry.network_id
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
