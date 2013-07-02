# -*- coding: utf-8 -*-

require 'celluloid'

module Vnmgr::VNet::Openflow

  class Switch
    include Constants
    include Celluloid
    include Celluloid::Logger

    attr_reader :datapath
    attr_reader :bridge_hw
    attr_reader :ports
    attr_reader :cookie_manager
    attr_reader :dc_segment_manager
    attr_reader :network_manager
    attr_reader :packet_manager
    attr_reader :tunnel_manager

    def initialize(dp, name = nil)
      @datapath = dp
      @datapath.switch = self

      @cookie_manager = CookieManager.new
      @cookie_manager.create_category(:switch, 0x1, 48)
      @cookie_manager.create_category(:packet_handler, 0x2, 48)
      @cookie_manager.create_category(:port, 0x3, 48)
      @cookie_manager.create_category(:network, 0x4, 48)
      @cookie_manager.create_category(:dc_segment, 0x5, 48)

      @ports = {}
      @dc_segment_manager = DcSegmentManager.new(dp)
      @network_manager = NetworkManager.new(dp)
      @packet_manager = PacketManager.new(dp)
      @tunnel_manager = TunnelManager.new(dp)

      @default_flow_cookie = @cookie_manager.acquire(:switch)
      @catch_flow_cookie = @cookie_manager.acquire(:switch)
    end

    def eth_ports
      self.ports.values.find_all{|port| port.eth? }
    end

    def tunnel_ports
      self.ports.values.find_all{|port| port.tunnel? }
    end

    def update_bridge_hw(hw_addr)
      @bridge_hw = hw_addr
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

      flow_options = {:cookie => @default_flow_cookie}

      flows << Flow.create(TABLE_CLASSIFIER, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_HOST_PORTS, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_DST, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_PHYSICAL_SRC, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_VIRTUAL_SRC, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_VIRTUAL_DST, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_ARP_ANTISPOOF, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_ARP_ROUTE, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_METADATA_LOCAL, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_METADATA_SEGMENT, 0, {}, {}, flow_options)
      flows << Flow.create(TABLE_METADATA_TUNNEL, 0, {}, {}, flow_options)

      flow_options = {:cookie => @catch_flow_cookie}

      # Catches all arp packets that are from local ports.
      #
      # All local ports have the port part of metadata [0,31] zero'ed
      # at this point.
      flows << Flow.create(TABLE_VIRTUAL_SRC, 84, {
                             :eth_type => 0x0806,
                             :metadata => 0x0,
                             :metadata_mask => (METADATA_PORT_MASK)
                           }, {}, flow_options)
      # Next we catch all arp packets, with learning flows for
      # incoming arp packets having been handled by network/eth_port
      # specific flows.
      flows << Flow.create(TABLE_VIRTUAL_SRC, 80, {
                             :eth_type => 0x0806,
                           }, {}, flow_options)

      self.datapath.add_flows(flows)

      p self.datapath.ovs_ofctl
      flow = "table=#{TABLE_CLASSIFIER},priority=1,tun_id=0x0/0x%x,actions=" % TUNNEL_FLAG
      self.datapath.ovs_ofctl.add_ovs_flow(flow)
      flow = "table=#{TABLE_CLASSIFIER},priority=1,tun_id=0x%x/0x%x,actions=goto_table:#{TABLE_GRE_PORTS}" % [
        TUNNEL_FLAG,
        TUNNEL_FLAG
      ]
      self.datapath.ovs_ofctl.add_ovs_flow(flow)
    end

    def features_reply(message)
      debug "transaction_id: %#x" % message.transaction_id
      debug "n_buffers: %u" % message.n_buffers
      debug "n_tables: %u" % message.n_tables
      debug "capabilities: %u" % message.capabilities
    end

    def handle_port_desc(port_desc)
      debug "handle_port_desc: #{port_desc.inspect}"

      self.bridge_hw || raise("No bridge hw address found.")

      port = Port.new(datapath, port_desc, true)
      ports[port_desc.port_no] = port

      if port.port_number >= OFPP_LOCAL
        port.extend(PortLocal)
        port.install_with_hw(self.bridge_hw) if self.bridge_hw

        network = self.network_manager.network_by_uuid('nw-public')

      elsif port.port_info.name =~ /^eth/
        port.extend(PortHost)

        network = self.network_manager.network_by_uuid('nw-public')

      elsif port.port_info.name =~ /^vif-/
        vif_map = Vnmgr::ModelWrappers::Vif[port_desc.name]

        if vif_map.nil?
          error "error: Could not find uuid: #{port_desc.name}"
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
        port.extend(PortTunnel)
      else
        error "Unknown interface type: #{port.port_info.name}"
        return
      end

      network.add_port(port, true) if network
      port.install
    end

    def port_status(message)
      debug "name: #{message.name}"
      debug "reason: #{message.reason}"
      debug "port_no: #{message.port_no}"
      debug "hw_addr: #{message.hw_addr}"
      debug "state: %#x" % message.state

      case message.reason
      when OFPPR_ADD
        debug "adding port"
        self.handle_port_desc(message)

      when OFPPR_DELETE
        debug "deleting port"

        port = @ports.delete(message.port_no)

        if port.nil?
          debug "port status could not delete uninitialized port: #{message.port_no}"
          return
        end
        
        port.uninstall

        if port.network
          network = port.network
          network.del_port(port, true)

          @network_manager.remove(network) if network.ports.empty?
        end
      end
    end

    def packet_in(message)
      port = @ports[message.match.in_port]

      @packet_manager.async.packet_in(port, message) if port
    end

  end

end
