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

    def initialize(dp, name = nil)
      @datapath = dp
      @ports = {}
      @network_manager = NetworkManager.new(dp)
    end

    #
    # Event handlers:
    #

    def switch_ready
      # There's a short period of time between the switch being
      # activated and features_reply installing flow.
      self.datapath.send_message(Trema::Messages::FeaturesRequest.new)
      self.datapath.send_message(Trema::Messages::PortDescMultipartRequest.new)
    end

    def features_reply(message)
      p "transaction_id: %#x" % message.transaction_id
      p "n_buffers: %u" % message.n_buffers
      p "n_tables: %u" % message.n_tables
      p "capabilities: %u" % message.capabilities

    end

    def handle_port_desc(port_desc)
      p "handle_port_desc: #{port_desc.inspect}"

      port = Port.new(datapath, port_desc, true)
      ports[port_desc.port_no] = port

      if port.port_number >= OFPP_LOCAL
        port.extend(PortLocal)
        port.install_with_hw(self.bridge_hw) if self.bridge_hw

      elsif port.port_info.name =~ /^eth/
        port.extend(PortHost)

        if self.bridge_hw.nil?
          @bridge_hw = port.port_info.hw_addr
          ports[OFPP_LOCAL].install_with_hw(self.bridge_hw) if ports[OFPP_LOCAL]
        end

      elsif port.port_info.name =~ /^vif-/
        port.extend(PortPhysical)
        port.hw_addr = Trema::Mac.new('52:54:00:bc:75:0e')

      elsif port.port_info.name =~ /^t-/
      else
        p "Unknown interface type: #{port.port_info.name}"
        return
      end

      port.install
      self.network_manager.network_by_uuid('nw-public').add_port(port)
    end

    def port_status(message)
      p "name: #{message.name}"
      p "reason: #{message.reason}"
      p "in_port: #{message.port_no}"
      p "hw_addr: #{message.hw_addr}"
      p "state: %#x" % message.state

      p message.inspect

      case message.reason
      when OFPPR_ADD
        p "adding port"
        self.handle_port_desc(message)

      when OFPPR_DELETE
        p "deleting port"

        port = @ports.delete(message.port_no)

        if port.nil?
          p "port status could not delete uninitialized port: #{message.port_no}"
          return
        end
        
        self.network_manager.network_by_uuid('nw-public').del_port(port)
        port.uninstall
      end
    end

    def packet_in(message)
    end

  end

end
