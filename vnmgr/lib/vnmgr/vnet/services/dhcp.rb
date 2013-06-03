# -*- coding: utf-8 -*-

require 'net/dhcp'
require 'racket'

module Vnmgr::VNet::Services

  class Dhcp < Vnmgr::VNet::Openflow::PacketHandler

    attr_reader :network
    attr_reader :service_mac
    attr_reader :service_ipv4

    def initialize(params)
      @datapath = params[:datapath]
      @network = params[:network]
      @service_mac = params[:service_mac]
      @service_ipv4 = params[:service_ipv4]
    end

    def packet_in(port, message)
      p "Dhcp.packet_in called."

      dhcp_in, message_type = parse_dhcp_packet(message)
      return if dhcp_in.nil? || message_type.empty? || message_type[0].payload.empty?

      # Verify dhcp_in values...

      params = {
        :xid => dhcp_in.xid,
        :yiaddr => port.ipv4_addr,
        :chaddr => port.hw_addr,
      }

      case message_type[0].payload[0]
      when $DHCP_MSG_DISCOVER
        p "DHCP send: DHCP_MSG_OFFER."
        params[:dhcp_class] = DHCP::Offer
        params[:message_type] = $DHCP_MSG_OFFER
      when $DHCP_MSG_REQUEST
        p "DHCP send: DHCP_MSG_ACK."
        params[:dhcp_class] = DHCP::ACK
        params[:message_type] = $DHCP_MSG_ACK
      else
        p "DHCP send: no handler."
        return
      end
      
      dhcp_out = create_dhcp_packet(params)

      p "DHCP send: output:#{dhcp_out.to_s}."

      send_udp({ :out_port => message.in_port,
                 :src_hw => self.service_mac,
                 :src_ip => self.service_ipv4,
                 :src_port => 67,
                 :dst_hw => port.hw_addr,
                 :dst_ip => port.ipv4_addr,
                 :dst_port => 68,
                 :payload => dhcp_out.pack
               })
    end

    def parse_dhcp_packet(message)
      if !message.udp?
        p "DHCP: Message is not UDP."
        return nil
      end
      
      raw_in_l2, raw_in_l3, raw_in_l4 = udp_in(message)

      dhcp_in = DHCP::Message.from_udp_payload(raw_in_l4.payload)
      message_type = dhcp_in.options.select { |each| each.type == $DHCP_MESSAGETYPE }

      p "DHCP: message:#{dhcp_in.to_s}."

      [dhcp_in, message_type]
    end

    def create_dhcp_packet(params)
      dhcp_out = params[:dhcp_class].new(:options => [DHCP::MessageTypeOption.new(:payload => [params[:message_type]])])

      # Verify instead that discover has the right mac address.
      dhcp_out.xid = params[:xid]
      dhcp_out.yiaddr = params[:yiaddr].to_i # port.ip
      dhcp_out.chaddr = params[:chaddr].to_a # port.mac
      dhcp_out.siaddr = self.service_ipv4.to_i

      subnet_mask = IPAddr.new(IPAddr::IN4MASK, Socket::AF_INET).mask(self.network.ipv4_prefix)

      dhcp_out.options << DHCP::ServerIdentifierOption.new(:payload => self.service_ipv4.hton.unpack('C*'))
      dhcp_out.options << DHCP::IPAddressLeaseTimeOption.new(:payload => [ 0xff, 0xff, 0xff, 0xff ])
      dhcp_out.options << DHCP::BroadcastAddressOption.new(:payload => (self.network.ipv4_network | ~subnet_mask).hton.unpack('C*'))

      # if nw_services[:gateway]
      #   dhcp_out.options << DHCP::RouterOption.new(:payload => nw_services[:gateway].ip.to_short)
      # end

      dhcp_out.options << DHCP::SubnetMaskOption.new(:payload => subnet_mask.hton.unpack('C*'))

      # if nw_services[:dns]
      #   dhcp_out.options << DHCP::DomainNameOption.new(:payload => nw_services[:dns].domain_name.unpack('C*')) if nw_services[:dns].domain_name
      #   dhcp_out.options << DHCP::DomainNameServerOption.new(:payload => nw_services[:dns].ip.to_short) if nw_services[:dns].ip
      # end

      dhcp_out
    end

  end

end
