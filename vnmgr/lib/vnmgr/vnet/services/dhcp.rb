# -*- coding: utf-8 -*-

require 'net/dhcp'
require 'racket'

module Vnmgr::VNet::Services

  class Dhcp < Vnmgr::VNet::Openflow::PacketHandler

    def packet_in(message)
      p "Dhcp.packet_in called."

      if !message.udp?
        p "DHCP: Message is not UDP."
        return
      end
      
      raw_in_l2 = Racket::L2::Ethernet.new(message.data.pack('C*'))
      raw_in_l3 = Racket::L3::IPv4.new(raw_in_l2.payload)
      raw_in_l4 = Racket::L4::UDP.new(raw_in_l3.payload)

      p "DHCP: raw_in_l2:#{raw_in_l2.pretty}."
      p "DHCP: raw_in_l3:#{raw_in_l3.pretty}."
      p "DHCP: raw_in_l4:#{raw_in_l4.pretty}."

      dhcp_in = DHCP::Message.from_udp_payload(raw_in_l4.payload)
      
      p "DHCP: message:#{dhcp_in.to_s}."

      # Check incoming type...
      message_type = dhcp_in.options.select { |each| each.type == $DHCP_MESSAGETYPE }
      return if message_type.empty? or message_type[0].payload.empty?

      # Verify dhcp_in values...

      if message_type[0].payload[0] == $DHCP_MSG_DISCOVER
        p "DHCP send: DHCP_MSG_OFFER."
        dhcp_out = DHCP::Offer.new(:options => [DHCP::MessageTypeOption.new(:payload => [$DHCP_MSG_OFFER])])
      elsif message_type[0].payload[0] == $DHCP_MSG_REQUEST
        p "DHCP send: DHCP_MSG_ACK."
        dhcp_out = DHCP::ACK.new(:options => [DHCP::MessageTypeOption.new(:payload => [$DHCP_MSG_ACK])])
      else
        p "DHCP send: no handler."
        return
      end

      # Verify instead that discover has the right mac address.
      dhcp_out.xid = dhcp_in.xid
      # dhcp_out.yiaddr = Trema::IP.new(port.ip).to_i
      # dhcp_out.chaddr = Trema::Mac.new(port.mac).to_a
      # dhcp_out.siaddr = self.ip.to_i
      dhcp_out.yiaddr = IPAddr.new('10.102.0.10').to_i
      dhcp_out.chaddr = Trema::Mac.new('52:54:00:cf:44:41').to_a
      dhcp_out.siaddr = IPAddr.new('10.102.0.1').to_i

      # subnet_mask = IPAddr.new(IPAddr::IN4MASK, Socket::AF_INET).mask(network.prefix)
      subnet_mask = IPAddr.new(IPAddr::IN4MASK, Socket::AF_INET).mask(24)

      # dhcp_out.options << DHCP::ServerIdentifierOption.new(:payload => self.ip.to_short)
      dhcp_out.options << DHCP::ServerIdentifierOption.new(:payload => IPAddr.new('10.102.0.1').hton.unpack('C*'))
      dhcp_out.options << DHCP::IPAddressLeaseTimeOption.new(:payload => [ 0xff, 0xff, 0xff, 0xff ])
      # dhcp_out.options << DHCP::BroadcastAddressOption.new(:payload => (network.ipv4_network | ~subnet_mask).to_short)
      dhcp_out.options << DHCP::BroadcastAddressOption.new(:payload => (IPAddr.new('10.102.0.1') | ~subnet_mask).hton.unpack('C*'))

      # if nw_services[:gateway]
      #   dhcp_out.options << DHCP::RouterOption.new(:payload => nw_services[:gateway].ip.to_short)
      # end

      dhcp_out.options << DHCP::SubnetMaskOption.new(:payload => subnet_mask.hton.unpack('C*'))

      # if nw_services[:dns]
      #   dhcp_out.options << DHCP::DomainNameOption.new(:payload => nw_services[:dns].domain_name.unpack('C*')) if nw_services[:dns].domain_name
      #   dhcp_out.options << DHCP::DomainNameServerOption.new(:payload => nw_services[:dns].ip.to_short) if nw_services[:dns].ip
      # end
      
      p "DHCP send: output:#{dhcp_out.to_s}."
      # switch.datapath.send_udp(message.in_port,
      #                          self.mac.to_s, self.ip.to_s, 67,
      #                          port.mac.to_s, port.ip, 68,
      #                          dhcp_out.pack)
    end

  end

end
