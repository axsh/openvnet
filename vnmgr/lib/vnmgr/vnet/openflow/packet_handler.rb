# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class PacketHandler

    attr_reader :datapath
    attr_accessor :cookie

    def initialize(dp)
      @datapath = dp
    end

    def packet_in(port, message)
      p "PacketHandler.packet_in called."
    end

    def packet_out(data)
      p "PacketHandler.packet_out called."
    end

    def catch_flow(type, match)
      case type
      when :physical_local
        table = Constants::TABLE_PHYSICAL_DST
        priority = 70
        match = match.merge(self.network.metadata_flags(Constants::METADATA_FLAG_LOCAL))
      when :virtual_local
        table = Constants::TABLE_VIRTUAL_DST
        priority = 70
        match = match.merge(self.network.metadata_pn)
      else
        raise "Wrong type for catch_flow."
      end

      self.datapath.add_flow(Flow.create(table, priority, match, {
                                           :output => Controller::OFPP_CONTROLLER
                                         }, {
                                           :cookie => @cookie
                                         }))
    end

    def arp_out(data)
    end

    def udp_in(message)
      raw_in_l2 = Racket::L2::Ethernet.new(message.data.pack('C*'))
      raw_in_l3 = Racket::L3::IPv4.new(raw_in_l2.payload)
      raw_in_l4 = Racket::L4::UDP.new(raw_in_l3.payload)

      p "DHCP: raw_in_l2:#{raw_in_l2.pretty}."
      p "DHCP: raw_in_l3:#{raw_in_l3.pretty}."
      p "DHCP: raw_in_l4:#{raw_in_l4.pretty}."

      [raw_in_l2, raw_in_l3, raw_in_l4]
    end

    def udp_out(params)
      raw_out = Racket::Racket.new
      raw_out.l2 = Racket::L2::Ethernet.new
      raw_out.l2.src_mac = params[:src_hw].to_s
      raw_out.l2.dst_mac = params[:dst_hw].to_s

      raw_out.l3 = Racket::L3::IPv4.new
      raw_out.l3.src_ip = params[:src_ip].to_s
      raw_out.l3.dst_ip = params[:dst_ip].to_s
      raw_out.l3.protocol = 0x11
      raw_out.l3.ttl = 128

      raw_out.l4 = Racket::L4::UDP.new
      raw_out.l4.src_port = params[:src_port]
      raw_out.l4.dst_port = params[:dst_port]
      raw_out.l4.payload = params[:payload]

      raw_out.l4.fix!(raw_out.l3.src_ip, raw_out.l3.dst_ip)

      raw_out.layers.compact.each { |l|
        p "send udp: layer:#{l.pretty}."
      }

      message = Trema::Messages::PacketIn.new({:data => raw_out.pack.ljust(64, '\0').unpack('C*')})

      self.datapath.send_packet_out(message, params[:out_port])
    end

  end

end
