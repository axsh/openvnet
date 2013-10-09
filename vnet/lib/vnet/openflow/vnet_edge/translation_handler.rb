# -*- coding: utf-8 -*-

module Vnet::Openflow::VnetEdge
  class TranslationHandler < Vnet::Openflow::PacketHandler

    include Celluloid::Logger

    def initialize(params)
      @datapath = params[:datapath]
      @translation_manager = @datapath.translation_manager
      @interface_manager = @datapath.interface_manager
    end

    def packet_in(message)
      debug log_format('packet_in', message.inspect)

      in_port = message.in_port
      vlan_vid = message.vlan_vid
      mac = message.packet_info.eth_src.to_s
      edge_port = translation_manager.find_edge_port(in_port)
      network_id = translation_manager.find_network_id(edge_port.id, vlan_vid)

      cookie = {:cookie => in_port | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT)}
      md = cookie.merge(md_create(:network => network_id))

      @datapath.add_flow(Flow.create(TABLE_VLAN_TRANLATION, 2, {
                          :in_port => in_port,
                          :dl_vlan => vlan_vid
                         }, {
                          :strip_vlan => true,
                         }, md.merge({:goto_table => TABLE_ROUTER_CLASSIFIER})))

      @datapath.add_flow(Flow.create(TABLE_VLAN_TRANLATION, 2, {
                          :eth_dst => mac
                         }, {
                          :mod_vlan_vid => vlan_vid,
                         }, cookie.merge({:output => in_port})))

      @datapath.send_packet_out(message, message.in_port)
    end

    def install
      debug log_format('install')
    end

    private

    def log_format(message, values = nil)
      "#{@dpid_s} translation_handler: #{message}" + (values ? " (#{values})" : '')
    end
  end
end
