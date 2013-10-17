# -*- coding: utf-8 -*-

module Vnet::Openflow

  class PacketHandler
    include Celluloid::Logger
    include FlowHelpers

    attr_reader :datapath
    attr_accessor :cookie
    attr_accessor :tag

    def initialize(dp)
      @datapath = dp
    end

    def packet_in(port, message)
      error "PacketHandler.packet_in called."
    end

    def packet_out(data)
      error "PacketHandler.packet_out called."
    end

    def catch_flow(type, match, params = {})
      case type
      when :arp_lookup
        table = TABLE_ARP_LOOKUP
        priority = 20
        match = match.merge(md_create({ :network => params[:network_id],
                                        :not_no_controller => nil
                                      }))
      when :network
        table = case params[:network_type]
                when :physical then TABLE_PHYSICAL_DST
                when :virtual  then TABLE_VIRTUAL_DST
                else
                  raise "Invalid network type value."
                end
        priority = 70
        match = match.merge(md_create(:network => params[:network_id]))
      when :physical_local
        table = TABLE_PHYSICAL_DST
        priority = 70
        match = match.merge(md_create(:network => params[:network_id]))
      when :virtual_local
        table = TABLE_VIRTUAL_DST
        priority = 70
        match = match.merge(md_create(:network => params[:network_id]))
      else
        raise "Wrong type for catch_flow."
      end

      @datapath.add_flow(Flow.create(table, priority, match, {
                                       :output => Controller::OFPP_CONTROLLER
                                     }, {
                                       :cookie => @cookie
                                     }))
    end

    def arp_out(params)
      raw_out = Racket::Racket.new
      raw_out.l2 = Racket::L2::Ethernet.new
      raw_out.l2.ethertype = Racket::L2::Ethernet::ETHERTYPE_ARP
      raw_out.l2.src_mac = params[:eth_src] ? params[:eth_src].to_s : '00:00:00:00:00:00'
      raw_out.l2.dst_mac = params[:eth_dst] ? params[:eth_dst].to_s : 'FF:FF:FF:FF:FF:FF'

      raw_out.l3 = Racket::L3::ARP.new
      raw_out.l3.opcode = params[:op_code]
      raw_out.l3.sha = params[:sha] ? params[:sha].to_s : '00:00:00:00:00:00'
      raw_out.l3.spa = params[:spa] ? params[:spa].to_s : '0.0.0.0'
      raw_out.l3.tha = params[:tha] ? params[:tha].to_s : '00:00:00:00:00:00'
      raw_out.l3.tpa = params[:tpa] ? params[:tpa].to_s : '0.0.0.0'

      # raw_out.layers.compact.each { |l|
      #   debug "send arp: layer:#{l.pretty}."
      # }

      packet_params = {
        :data => raw_out.pack.ljust(64, '\0').unpack('C*')
      }

      if params[:in_port]
        packet_params[:datapath_id] = @datapath.dpid
        packet_params[:buffer_id] = OFP_NO_BUFFER
        packet_params[:match] = Trema::Match.new(:in_port => params[:in_port])
      end

      message = Trema::Messages::PacketIn.new(packet_params)

      @datapath.send_packet_out(message, params[:out_port])
    end

    def icmpv4_in(message)
      raw_in = Racket::Racket.new
      raw_in.l2 = Racket::L2::Ethernet.new(message.data.pack('C*'))
      raw_in.l3 = Racket::L3::IPv4.new(raw_in.l2.payload)

      raw_l4_in = Racket::L4::ICMPGeneric.new(raw_in.l3.payload)

      case raw_l4_in.type
      when Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REQUEST
        raw_in.l4 = Racket::L4::ICMPEchoRequest.new(raw_in.l3.payload)
      when Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REPLY
        raw_in.l4 = Racket::L4::ICMPEchoReply.new(raw_in.l3.payload)
      else
        raw_in.l4 = raw_l4_in
      end

      # raw_in.layers.compact.each { |l|
      #   debug "ICMP packet: layer:#{l.pretty}."
      # }

      raw_in
    end

    def icmpv4_out(params)
      raw_out = Racket::Racket.new
      raw_out.l2 = Racket::L2::Ethernet.new
      raw_out.l2.src_mac = params[:eth_src].to_s
      raw_out.l2.dst_mac = params[:eth_dst].to_s

      raw_out.l3 = Racket::L3::IPv4.new
      raw_out.l3.src_ip = params[:ipv4_src].to_s
      raw_out.l3.dst_ip = params[:ipv4_dst].to_s
      raw_out.l3.protocol = IPV4_PROTOCOL_ICMP
      raw_out.l3.ttl = 128

      case params[:icmpv4_type]
      when Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REPLY
        raw_out.l4 = Racket::L4::ICMPEchoReply.new
        raw_out.l4.id = params[:icmpv4_id]
        raw_out.l4.sequence = params[:icmpv4_sequence]
      else
        error "packet_handler: unsupported ICMP type '#{params[:op_code]}'"
        return
      end

      raw_out.l4.payload = params[:payload] if params[:payload]
      raw_out.l4.fix!

      # raw_out.layers.compact.each { |l|
      #   debug "ICMP packet: layer:#{l.pretty}."
      # }

      message = Trema::Messages::PacketIn.new({:data => raw_out.pack.ljust(64, '\0').unpack('C*')})

      @datapath.send_packet_out(message, params[:out_port])
    end

    def udp_in(message)
      raw_in_l2 = Racket::L2::Ethernet.new(message.data.pack('C*'))
      raw_in_l3 = Racket::L3::IPv4.new(raw_in_l2.payload)
      raw_in_l4 = Racket::L4::UDP.new(raw_in_l3.payload)

      # debug "DHCP: raw_in_l2:#{raw_in_l2.pretty}."
      # debug "DHCP: raw_in_l3:#{raw_in_l3.pretty}."
      # debug "DHCP: raw_in_l4:#{raw_in_l4.pretty}."

      [raw_in_l2, raw_in_l3, raw_in_l4]
    end

    def udp_out(params)
      raw_out = Racket::Racket.new
      raw_out.l2 = Racket::L2::Ethernet.new
      raw_out.l2.src_mac = params[:eth_src].to_s
      raw_out.l2.dst_mac = params[:eth_dst].to_s

      raw_out.l3 = Racket::L3::IPv4.new
      raw_out.l3.src_ip = params[:src_ip].to_s
      raw_out.l3.dst_ip = params[:dst_ip].to_s
      raw_out.l3.protocol = IPV4_PROTOCOL_UDP
      raw_out.l3.ttl = 128

      raw_out.l4 = Racket::L4::UDP.new
      raw_out.l4.src_port = params[:src_port]
      raw_out.l4.dst_port = params[:dst_port]
      raw_out.l4.payload = params[:payload]

      raw_out.l4.fix!(raw_out.l3.src_ip, raw_out.l3.dst_ip)

      # raw_out.layers.compact.each { |l|
      #   debug "send udp: layer:#{l.pretty}."
      # }

      message = Trema::Messages::PacketIn.new({:data => raw_out.pack.ljust(64, '\0').unpack('C*')})

      @datapath.send_packet_out(message, params[:out_port])
    end

  end

  module PacketHelpers

    def packet_arp_out(params)
      raw_out = Racket::Racket.new
      raw_out.l2 = Racket::L2::Ethernet.new
      raw_out.l2.ethertype = Racket::L2::Ethernet::ETHERTYPE_ARP
      raw_out.l2.src_mac = params[:eth_src] ? params[:eth_src].to_s : '00:00:00:00:00:00'
      raw_out.l2.dst_mac = params[:eth_dst] ? params[:eth_dst].to_s : 'FF:FF:FF:FF:FF:FF'

      raw_out.l3 = Racket::L3::ARP.new
      raw_out.l3.opcode = params[:op_code]
      raw_out.l3.sha = params[:sha] ? params[:sha].to_s : '00:00:00:00:00:00'
      raw_out.l3.spa = params[:spa] ? params[:spa].to_s : '0.0.0.0'
      raw_out.l3.tha = params[:tha] ? params[:tha].to_s : '00:00:00:00:00:00'
      raw_out.l3.tpa = params[:tpa] ? params[:tpa].to_s : '0.0.0.0'

      # raw_out.layers.compact.each { |l|
      #   debug "send arp: layer:#{l.pretty}."
      # }

      packet_params = {
        :data => raw_out.pack.ljust(64, '\0').unpack('C*')
      }

      if params[:in_port]
        packet_params[:datapath_id] = @dp_info.dpid
        packet_params[:buffer_id] = OFP_NO_BUFFER
        packet_params[:match] = Trema::Match.new(:in_port => params[:in_port])
      end

      message = Trema::Messages::PacketIn.new(packet_params)

      @dp_info.send_packet_out(message, params[:out_port])
    end

    def packet_udp_in(message)
      raw_in_l2 = Racket::L2::Ethernet.new(message.data.pack('C*'))
      raw_in_l3 = Racket::L3::IPv4.new(raw_in_l2.payload)
      raw_in_l4 = Racket::L4::UDP.new(raw_in_l3.payload)

      # debug "DHCP: raw_in_l2:#{raw_in_l2.pretty}."
      # debug "DHCP: raw_in_l3:#{raw_in_l3.pretty}."
      # debug "DHCP: raw_in_l4:#{raw_in_l4.pretty}."

      [raw_in_l2, raw_in_l3, raw_in_l4]
    end

    def packet_udp_out(params)
      raw_out = Racket::Racket.new
      raw_out.l2 = Racket::L2::Ethernet.new
      raw_out.l2.src_mac = params[:eth_src].to_s
      raw_out.l2.dst_mac = params[:eth_dst].to_s

      raw_out.l3 = Racket::L3::IPv4.new
      raw_out.l3.src_ip = params[:src_ip].to_s
      raw_out.l3.dst_ip = params[:dst_ip].to_s
      raw_out.l3.protocol = IPV4_PROTOCOL_UDP
      raw_out.l3.ttl = 128

      raw_out.l4 = Racket::L4::UDP.new
      raw_out.l4.src_port = params[:src_port]
      raw_out.l4.dst_port = params[:dst_port]
      raw_out.l4.payload = params[:payload]

      raw_out.l4.fix!(raw_out.l3.src_ip, raw_out.l3.dst_ip)

      # raw_out.layers.compact.each { |l|
      #   debug "send udp: layer:#{l.pretty}."
      # }

      message = Trema::Messages::PacketIn.new({:data => raw_out.pack.ljust(64, '\0').unpack('C*')})

      @dp_info.send_packet_out(message, params[:out_port])
    end

    def icmpv4_in(message)
      raw_in = Racket::Racket.new
      raw_in.l2 = Racket::L2::Ethernet.new(message.data.pack('C*'))
      raw_in.l3 = Racket::L3::IPv4.new(raw_in.l2.payload)

      raw_l4_in = Racket::L4::ICMPGeneric.new(raw_in.l3.payload)

      case raw_l4_in.type
      when Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REQUEST
        raw_in.l4 = Racket::L4::ICMPEchoRequest.new(raw_in.l3.payload)
      when Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REPLY
        raw_in.l4 = Racket::L4::ICMPEchoReply.new(raw_in.l3.payload)
      else
        raw_in.l4 = raw_l4_in
      end

      # raw_in.layers.compact.each { |l|
      #   debug "ICMP packet: layer:#{l.pretty}."
      # }

      raw_in
    end

    def icmpv4_out(params)
      raw_out = Racket::Racket.new
      raw_out.l2 = Racket::L2::Ethernet.new
      raw_out.l2.src_mac = params[:eth_src].to_s
      raw_out.l2.dst_mac = params[:eth_dst].to_s

      raw_out.l3 = Racket::L3::IPv4.new
      raw_out.l3.src_ip = params[:ipv4_src].to_s
      raw_out.l3.dst_ip = params[:ipv4_dst].to_s
      raw_out.l3.protocol = IPV4_PROTOCOL_ICMP
      raw_out.l3.ttl = 128

      case params[:icmpv4_type]
      when Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REPLY
        raw_out.l4 = Racket::L4::ICMPEchoReply.new
        raw_out.l4.id = params[:icmpv4_id]
        raw_out.l4.sequence = params[:icmpv4_sequence]
      else
        error "packet_handler: unsupported ICMP type '#{params[:op_code]}'"
        return
      end

      raw_out.l4.payload = params[:payload] if params[:payload]
      raw_out.l4.fix!

      # raw_out.layers.compact.each { |l|
      #   debug "ICMP packet: layer:#{l.pretty}."
      # }

      message = Trema::Messages::PacketIn.new({:data => raw_out.pack.ljust(64, '\0').unpack('C*')})

      @dp_info.send_packet_out(message, params[:out_port])
    end

  end

end
