# -*- coding: utf-8 -*-

require 'celluloid'

module Vnmgr::VNet::Openflow

  class Switch
    # include OpenFlowConstants
    include Celluloid

    attr_reader :datapath
    attr_reader :ports
    attr_reader :networks
    # attr_reader :switch_name
    # attr_reader :local_hw
    # attr_reader :eth_port
    # attr_reader :bridge_ipv4

    # attr_accessor :packet_handlers

    def initialize dp, name = nil
      @datapath = dp
      @ports = {}
      @networks = {}
      # @switch_name = name
      # @eth_port = nil

      # @packet_handlers = []
    end

    # def update_bridge_ipv4
    #   @bridge_ipv4 = nil

    #   ip = case `/bin/uname -s`.rstrip
    #        when 'Linux'
    #          `/sbin/ip addr show #{self.switch_name} | awk '$1 == "inet" { print $2 }'`.split('/')[0]
    #        when 'SunOS'
    #          `/sbin/ifconfig #{self.switch_name} | awk '$1 == "inet" { print $2 }'`
    #        else
    #          raise "Unsupported platform to detect bridge IP address: #{`/bin/uname`}"
    #        end
    #   logger.info "Failed to run command to get inet address of bridge '#{self.switch_name}'." if $?.exitstatus != 0
    #   return if ip.nil?

    #   ip = ip.rstrip
    #   @bridge_ipv4 = ip unless ip.empty?
    # end

    #
    # Event handlers:
    #

    def switch_ready
      # p "switch_ready: datapath_id:%#x ipv4:#{self.bridge_ipv4}." % datapath.datapath_id
      p "switch_ready: datapath_id:%#x." % datapath.datapath_id
      # p "switch_ready: error:'bridge_ipv4 not set'" unless self.bridge_ipv4

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

      # message.ports.each do |each|
      #   if each.number == OpenFlowController::OFPP_LOCAL
      #     # 'local_hw' needs to be set before any networks or
      #     # ports are initialized.
      #     @local_hw = each.hw_addr
      #     p "OFPP_LOCAL: hw_addr:#{local_hw.to_s}"
      #   end
      # end

      # message.ports.each do |each|
      #   if each.name =~ /^eth/
      #     @eth_port = each.number

      #     port = OpenFlowPort.new(datapath, each)
      #     port.is_active = true
      #     ports[each.number] = port

      #     datapath.controller.insert_port self, port
      #   end
      # end

      # message.ports.each do |each|
      #   next if each.name =~ /^eth/

      #   port = OpenFlowPort.new(datapath, each)
      #   port.is_active = true
      #   ports[each.number] = port

      #   datapath.controller.insert_port self, port
      # end

      # Build the routing flow table and some other flows using
      # ovs-ofctl due to the lack of multiple tables support, which
      # was introduced in of-spec 1.1.

      #
      # Classification
      #
      flows = []

      # DHCP queries from instances and network should always go to
      # local host, while queries from local host should go to the
      # network.
      # flows << Flow.new(TABLE_CLASSIFIER, 3, {:arp => nil}, {:resubmit => TABLE_ARP_ANTISPOOF})
      # flows << Flow.new(TABLE_CLASSIFIER, 3, {:icmp => nil}, {:resubmit => TABLE_LOAD_DST})
      # flows << Flow.new(TABLE_CLASSIFIER, 3, {:tcp => nil}, {:resubmit => TABLE_LOAD_DST})
      # flows << Flow.new(TABLE_CLASSIFIER, 3, {:udp => nil}, {:resubmit => TABLE_LOAD_DST})

      # flows << Flow.new(TABLE_CLASSIFIER, 2, {:in_port => Controller::OFPP_LOCAL}, {:resubmit => TABLE_ROUTE_DIRECTLY})

      #
      # MAC address routing
      #

      # flows << Flow.new(TABLE_MAC_ROUTE, 1, {:dl_dst => local_hw.to_s}, {:local => nil})
      # flows << Flow.new(TABLE_ROUTE_DIRECTLY, 1, {:dl_dst => local_hw.to_s}, {:local => nil})
      # flows << Flow.new(TABLE_LOAD_DST, 1, {:dl_dst => local_hw.to_s}, [{:load_reg0 => Controller::OFPP_LOCAL}, {:resubmit => TABLE_LOAD_SRC}])

      # Some flows depend on only local being able to send packets
      # with the local mac and ip address, so drop those.
      # flows << Flow.new(TABLE_LOAD_SRC, 6, {:in_port => Controller::OFPP_LOCAL}, {:output_reg0 => nil})
      # flows << Flow.new(TABLE_LOAD_SRC, 5, {:dl_src => local_hw.to_s}, {:drop => nil})
      # flows << Flow.new(TABLE_LOAD_SRC, 5, {:ip => nil, :nw_src => self.bridge_ipv4}, {:drop =>nil}) if self.bridge_ipv4

      #
      # ARP routing table
      #

      # ARP anti-spoofing flows.
      # flows << Flow.new(TABLE_ARP_ANTISPOOF, 1, {:arp => nil, :in_port => Controller::OFPP_LOCAL}, {:resubmit => TABLE_ARP_ROUTE})

      # Replace drop actions with table default action.
      # flows << Flow.new(TABLE_ARP_ANTISPOOF, 0, {:arp => nil}, {:drop => nil})

      # TODO: How will this handle packets from host or eth0 that
      # spoof the mac of an instance?
      # flows << Flow.new(TABLE_ARP_ROUTE, 1, {:arp => nil, :dl_dst => local_hw.to_s}, {:local => nil})

      # datapath.add_flows flows
    end

    def port_desc_multipart_reply message
      message.parts.each { |port_descs| 
        p "port_desc_multipart_reply from %#x." % self.datapath.datapath_id
        p "ports: %s" % port_descs.ports.collect { |each| each.port_no }.sort.join( ", " )

        port_descs.ports.each { |port_msg|
          port = Port.new(datapath, port_msg, true)
          ports[port_msg.port_no] = port

          # datapath.controller.insert_port(self, port)
        }
      }
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
