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

    def eth_ports
      self.ports.find_all{ |key,port| port.is_eth_port }.collect{ |key,port| port }
    end

    #
    # Event handlers:
    #

    def switch_ready
      # There's a short period of time between the switch being
      # activated and features_reply installing flow.
      self.datapath.send_message(Trema::Messages::FeaturesRequest.new)
      self.datapath.send_message(Trema::Messages::PortDescMultipartRequest.new)

      flows = []

      # Catches all arp packets that are from local ports.
      #
      # All local ports have the port part of metadata [0,31] zero'ed
      # at this point.
      flows << Flow.create(TABLE_VIRTUAL_SRC, 84, {
                             :eth_type => 0x0806,
                             :metadata => 0x0,
                             :metadata_mask => (METADATA_PORT_MASK)
                           }, {}, {})
      # Next we catch all arp packets, with learning flows for
      # incoming arp packets having been handled by network/eth_port
      # specific flows.
      flows << Flow.create(TABLE_VIRTUAL_SRC, 80, {
                             :eth_type => 0x0806,
                           }, {}, {})

      self.datapath.add_flows(flows)
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

        network = self.network_manager.network_by_uuid('nw-public')

      elsif port.port_info.name =~ /^eth/
        port.extend(PortHost)

        if self.bridge_hw.nil?
          @bridge_hw = port.port_info.hw_addr
          ports[OFPP_LOCAL].install_with_hw(self.bridge_hw) if ports[OFPP_LOCAL]
        end

        network = self.network_manager.network_by_uuid('nw-public')

      elsif port.port_info.name =~ /^vif-/
        vif_map = Vnmgr::ModelWrappers::Vif[port_desc.name]

        if vif_map.nil?
          p "error: Could not find uuid: #{port_desc.name}"
          return
        end

        # network = self.network_manager.network_by_id(vif_map.network_id)
        network = self.network_manager.network_by_uuid(vif_map.batch.network.commit.uuid)

        if network.class == NetworkPhysical
          port.extend(PortPhysical)
        elsif network.class == NetworkVirtual
          port.extend(PortVirtual)
        else
          raise("Unknown network type.")
        end

        port.hw_addr = Trema::Mac.new(vif_map.mac_addr)
        port.ipv4_addr = IPAddr.new(vif_map.ipv4_address, Socket::AF_INET) if vif_map.ipv4_address

      elsif port.port_info.name =~ /^t-/
      else
        p "Unknown interface type: #{port.port_info.name}"
        return
      end

      network.add_port(port, true) if network
      port.install
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
        
        port.network.del_port(port, true) if port.network
        port.uninstall
      end
    end

    def packet_in(message)
    end

  end

end
