# -*- coding: utf-8 -*-

require 'celluloid'

module Vnmgr::VNet::Openflow

  class Switch
    include Constants
    include Celluloid

    attr_reader :datapath
    attr_reader :bridge_hw
    attr_reader :ports
    attr_reader :network_manager

    def initialize dp, name = nil
      @datapath = dp
      @ports = {}
      @network_manager = NetworkManager.new(dp)
    end

    #
    # Event handlers:
    #

    def switch_ready
      p "switch_ready: datapath_id:%#x." % datapath.datapath_id

      # There's a short period of time between the switch being
      # activated and features_reply installing flow.
      self.datapath.send_message(Trema::Messages::FeaturesRequest.new)
      self.datapath.send_message(Trema::Messages::PortDescMultipartRequest.new)
    end

    def features_reply message
      p "features_reply from %#x." % self.datapath.datapath_id
      p "transaction_id: %#x" % message.transaction_id
      p "n_buffers: %u" % message.n_buffers
      p "n_tables: %u" % message.n_tables
      p "capabilities: %u" % message.capabilities

    end

    def handle_port_desc port_desc
      p "begin #{port_desc.port_no}"
      p "#{port_desc.inspect}"

      port = Port.new(datapath, port_desc, true)
      ports[port_desc.port_no] = port

      if port.port_number >= OFPP_LOCAL
        port.extend(PortLocal)
        self.network_manager.network_by_uuid('nw-public').add_port(port)

        port.install_with_hw(self.bridge_hw) if self.bridge_hw

      elsif port.port_info.name =~ /^eth/
        port.extend(PortHost)
        self.network_manager.network_by_uuid('nw-public').add_port(port)

        if self.bridge_hw.nil?
          @bridge_hw = port.port_info.hw_addr
          ports[OFPP_LOCAL].install_with_hw(self.bridge_hw) if ports[OFPP_LOCAL]
        end

      elsif port.port_info.name =~ /^vif-/
        port.extend(PortPhysical)
        port.hw_addr = Trema::Mac.new('52:54:00:bc:75:0e')

        self.network_manager.network_by_uuid('nw-public').add_port(port)

      elsif port.port_info.name =~ /^t-/
      else
        p "Unknown interface type: #{port.port_info.name}"
      end

      port.install

      p "end #{port_desc.port_no}"
    end

    def port_status message
      p "port_status from %#x." % message.datapath_id
      p "datapath_id: %#x" % message.datapath_id
      p "reason: #{message.reason}"
      p "in_port: #{message.phy_port.number}"
      p "hw_addr: #{message.phy_port.hw_addr}"
      p "state: %#x" % message.phy_port.state

      # case message.reason
      # when Trema::PortStatus::OFPPR_ADD
      #   p "Adding port: port:#{message.phy_port.number} name:#{message.phy_port.name}."
      #   raise "OpenFlowPort" if ports.has_key? message.phy_port.number

      #   datapath.controller.delete_port(self, ports[message.phy_port.number]) if ports.has_key? message.phy_port.number

      #   port = OpenFlowPort.new(datapath, message.phy_port)
      #   port.is_active = true
      #   ports[message.phy_port.number] = port

      #   datapath.controller.insert_port self, port

      # when Trema::PortStatus::OFPPR_DELETE
      #   p "Deleting instance port: port:#{message.phy_port.number}."
      #   raise "UnknownOpenflowPort" if not ports.has_key? message.phy_port.number

      #   datapath.controller.delete_port(self, ports[message.phy_port.number]) if ports.has_key? message.phy_port.number

      # when Trema::PortStatus::OFPPR_MODIFY
      #   p "Ignoring port modify..."
      # end
    end

    def packet_in message
      # port = ports[message.in_port]

      # if port.nil?
      #   p "Dropping processing of packet, unknown port."
      #   return
      # end

      # if message.arp?
      #   p "Got ARP packet; switch_name:#{self.switch_name} port:#{message.in_port} network:#{port.networks.empty? ? 'nil' : port.networks.first.id} oper:#{message.arp_oper} source:#{message.arp_sha.to_s}/#{message.arp_spa.to_s} dest:#{message.arp_tha.to_s}/#{message.arp_tpa.to_s}."
      # elsif message.ipv4? and message.tcp?
      #   p "Got IPv4/TCP packet; switch_name:#{self.switch_name} port:#{message.in_port} network:#{port.networks.empty? ? 'nil' : port.networks.first.id} source:#{message.ipv4_saddr.to_s}:#{message.tcp_src_port} dest:#{message.ipv4_daddr.to_s}:#{message.tcp_dst_port}."
      # elsif message.ipv4? and message.udp?
      #   p "Got IPv4/UDP packet; switch_name:#{self.switch_name} port:#{message.in_port} source:#{message.ipv4_saddr.to_s}:#{message.udp_src_port} dest:#{message.ipv4_daddr.to_s}:#{message.udp_dst_port}."
      # else
      #   p "Got Unknown packet; switch_name:#{self.switch_name} port:#{message.in_port} source:#{message.macsa.to_s} dest:#{message.macda.to_s}."
      # end

      # port.networks.each { |network|
      #   network.packet_handlers.each { |handler| handler.handle(self, port, message) }
      # }

      # packet_handlers.each { |handler| handler.handle(self, port, message) }
    end

  end

end
