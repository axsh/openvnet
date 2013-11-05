# -*- coding: utf-8 -*-

module Vnet::Openflow::Translations
  class VnetEdgeHandler

    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :id

    def initialize(params)
      # TODO refactor
      @id = 1
      @dp_info = params[:dp_info]

      flows = []
      flows << Flow.create(TABLE_EDGE_SRC,   1, {}, {:output => Vnet::Openflow::Controller::OFPP_CONTROLLER}, {:cookie => @id | COOKIE_TYPE_TRANSLATION} )
      @dp_info.datapath.add_flows(flows)
    end

    def packet_in(message)
      debug log_format('packet_in', dump_packet_in(message))

      port = @dp_info.port_manager.item(port_number: message.in_port,
                                        reinitialize: false,
                                        dynamic_load: false)

      case port[:type]
      when :host
        handle_packet_from_host_port(
          in_port: message.in_port,
          src_mac: message.eth_src,
          dst_mac: message.eth_dst
        )
      when :generic
        handle_packet_from_edge_port(
          in_port: message.in_port,
          src_mac: message.eth_src,
          dst_mac: message.eth_dst,
          vlan_vid: message.vlan_vid
        )
      else
        error log_format("unknown type of port", port[:type])
      end
    end

    def install
      debug log_format('install')
    end

    private

    def handle_packet_from_host_port(params)
      flows = []

      in_port = params[:in_port]
      src_mac = params[:src_mac]
      dst_mac = params[:dst_mac]

      debug log_format('handle_packet_from_host_port : [src_mac]', src_mac)
      debug log_format('handle_packet_from_host_port : [src_mac.value]', src_mac.value)
      src_network_id = @dp_info.network_manager.network_id_by_mac(src_mac.value)

      return if src_network_id.nil?

      debug log_format('handle_packet_from_host_port : [src_network_id]', src_network_id)
      vlan_vids = @dp_info.translation_manager.network_to_vlan(src_network_id)

      return if vlan_vids.nil?

      flows << "table=#{TABLE_EDGE_SRC},priority=2,dl_src=#{src_mac},actions=write_metadata:0x%x,goto_table=#{TABLE_EDGE_DST}" % METADATA_TYPE_VIRTUAL_TO_EDGE

      case vlan_vids
      when Array
        actions=""
        vlan_vids.each do |vlan_vid|
          actions << "mod_vlan_vid:#{vlan_vid},output:2,"
        end
        actions.chop!
      else
        actions = "mod_vlan_vid:#{vlan_vids},output:2"
      end

      dpn = MW::DatapathNetwork.batch.on_specific_datapath(@dp_info.datapath.datapath_map).all.commit.select { |t| t.network_id == src_network_id }
      dpn_broadcast = dpn.first.broadcast_mac_address

      if dst_mac.broadcast?
        flows << "table=#{TABLE_EDGE_DST},priority=2,arp,dl_dst=ff:ff:ff:ff:ff:ff,metadata=0x%x/0x%x,actions=#{actions}" % [ METADATA_TYPE_VIRTUAL_TO_EDGE, METADATA_TYPE_MASK ]
      elsif dpn_broadcast == dst_mac.value
        flows << "table=#{TABLE_EDGE_DST},priority=2,arp,dl_dst=#{dst_mac},metadata=0x%x/0x%x,actions=mod_dl_dst:ff:ff:ff:ff:ff:ff,#{actions}" % [ METADATA_TYPE_VIRTUAL_TO_EDGE, METADATA_TYPE_MASK ]
      else
        flows << "table=#{TABLE_EDGE_DST},priority=2,dl_dst=#{src_mac},metadata=0x%x/0x%x,actions=output:1" %  [ METADATA_TYPE_EDGE_TO_VIRTUAL, METADATA_TYPE_MASK ]
      end

      flows.each { |flow| @dp_info.add_ovs_flow(flow) }
    end

    def handle_packet_from_edge_port(params)
      flows = []

      in_port = params[:in_port]
      src_mac = params[:src_mac]
      dst_mac = params[:dst_mac]
      vlan_vid = params[:vlan_vid]

      debug log_format('edge_port', in_port)
      debug log_format('edge_port', src_mac.inspect)
      debug log_format('edge_port', dst_mac.inspect)
      debug log_format('edge_port', vlan_vid)

      network_id = @dp_info.translation_manager.vlan_to_network(vlan_vid)

      flows << "table=#{TABLE_EDGE_SRC},priority=2,dl_src=#{src_mac},dl_vlan=#{vlan_vid},actions=strip_vlan,write_metadata:0x%x,goto_table:#{TABLE_EDGE_DST}" % METADATA_TYPE_EDGE_TO_VIRTUAL

      if dst_mac.broadcast?
        md = md_create(:network => network_id)
        flows << "table=#{TABLE_EDGE_DST},priority=2,arp,dl_dst=ff:ff:ff:ff:ff:ff,metadata=0x%x/0x%x,actions=write_metadata:0x%x/0x%x,goto_table:#{TABLE_VIRTUAL_DST}" % [ METADATA_TYPE_EDGE_TO_VIRTUAL, METADATA_TYPE_MASK, md[:metadata], md[:metadata_mask] ]
      end

      flows << "table=#{TABLE_EDGE_DST},priority=2,dl_dst=#{src_mac},metadata=0x%x/0x%x,actions=mod_vlan_vid:#{vlan_vid},output:2" % [ METADATA_TYPE_VIRTUAL_TO_EDGE, METADATA_TYPE_MASK ]

      flows.each { |flow| @dp_info.add_ovs_flow(flow) }

      network = @dp_info.network_manager.item(id: network_id)
    end

    def log_format(message, values = nil)
      "#{@dpid_s} translation_handler: #{message}" + (values ? " (#{values})" : '')
    end

    def dump_packet_in(message)
      output_str = ""
      output_str << "in_port=#{message.in_port},"
      output_str << "src=#{message.eth_src},"
      output_str << "dst=#{message.eth_dst},"
      output_str << "eth_type=#{message.eth_type},"
      output_str << "vlan_vid=#{message.vlan_vid},"
      output_str << "arp?=#{message.packet_info.arp},"
      output_str << "arp_request?=#{message.packet_info.arp_request},"
      output_str << "arp_reply?=#{message.packet_info.arp_reply},"
      output_str
    end
  end
end
