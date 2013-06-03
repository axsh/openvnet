# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class PacketHandler

    attr_reader :datapath

    def initialize(dp)
      @datapath = dp
    end

    def packet_in(port, message)
      p "PacketHandler.packet_in called."
    end

    def packet_out(data)
      p "PacketHandler.packet_out called."
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
      raw_out.l4.src_port = params[:src_port].to_s
      raw_out.l4.dst_port = params[:dst_port].to_s
      raw_out.l4.payload = params[:payload]

      raw_out.l4.fix!(raw_out.l3.src_ip, raw_out.l3.dst_ip)

      raw_out.layers.compact.each { |l|
        logger.debug "send udp: layer:#{l.pretty}."
      }

      # send_packet_out(datapath_id,
      #                 :data => raw_out.pack.ljust(64, "\0"),
      #                 :actions => Trema::ActionOutput.new( :port => out_port ) )
    end

  end

end
