# -*- coding: utf-8 -*-

require 'net/dhcp'
require 'racket'

module Vnet::Openflow::Services

  class Dhcp < Base

    def install
      flows = []
      flows << flow_create(:catch_interface_simulated,
                           match: {
                             :eth_type => 0x0800,
                             :ip_proto => 0x11,
                             :udp_dst => 67,
                             :udp_src => 68
                           },
                           interface_id: @interface_id,
                           cookie: self.cookie)

      @dp_info.add_flows(flows)
    end

    def packet_in(message)
      debug log_format('packet_in received')

      dhcp_in, message_type = parse_dhcp_packet(message)
      return if dhcp_in.nil? || message_type.empty? || message_type[0].payload.empty?

      # Verify dhcp_in values...

      mac_info, ipv4_info, network = find_ipv4_and_network(message, message.ipv4_dst)
      return if network.nil?

      client_info = find_client_infos(message.match.in_port, mac_info, ipv4_info).first
      return if client_info.nil?

      params = {
        :xid => dhcp_in.xid,
        :yiaddr => client_info[1][:ipv4_address],
        :chaddr => client_info[0][:mac_address],
        :ipv4_address => ipv4_info[:ipv4_address],
        :ipv4_network => network[:ipv4_network],
        :ipv4_prefix => network[:ipv4_prefix],
      }

      case message_type[0].payload[0]
      when $DHCP_MSG_DISCOVER
        debug log_format('DHCP send: DHCP_MSG_OFFER')
        params[:dhcp_class] = DHCP::Offer
        params[:message_type] = $DHCP_MSG_OFFER
      when $DHCP_MSG_REQUEST
        debug log_format('DHCP send: DHCP_MSG_ACK')
        params[:dhcp_class] = DHCP::ACK
        params[:message_type] = $DHCP_MSG_ACK
      else
        debug log_format('DHCP send: no handler')
        return
      end

      dhcp_out = create_dhcp_packet(params)

      debug log_format("DHCP send", "output:#{dhcp_out.to_s}")

      packet_udp_out({ :out_port => message.in_port,
                       :eth_src => mac_info[:mac_address],
                       :src_ip => ipv4_info[:ipv4_address],
                       :src_port => 67,
                       :eth_dst => client_info[0][:mac_address],
                       :dst_ip => client_info[1][:ipv4_address],
                       :dst_port => 68,
                       :payload => dhcp_out.pack
                     })
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} service/dhcp: #{message}" + (values ? " (#{values})" : '')
    end

    def find_client_infos(port_number, server_mac_info, server_ipv4_info)
      interface = @dp_info.interface_manager.item(port_number: port_number)
      return [] if interface.nil?

      client_infos = interface.get_ipv4_infos(network_id: server_ipv4_info && server_ipv4_info[:network_id])
      
      # info log_format("find_client_info", "#{interface.inspect}")
      # info log_format("find_client_info", "server_mac_info:#{server_mac_info.inspect}")
      # info log_format("find_client_info", "server_ipv4_info:#{server_ipv4_info.inspect}")
      # info log_format("find_client_info", "client_infos:#{client_infos.inspect}")

      client_infos
    end

    def parse_dhcp_packet(message)
      if !message.udp?
        debug log_format('DHCP: Message is not UDP')
        return nil
      end

      raw_in_l2, raw_in_l3, raw_in_l4 = packet_udp_in(message)

      dhcp_in = DHCP::Message.from_udp_payload(raw_in_l4.payload)
      message_type = dhcp_in.options.select { |each| each.type == $DHCP_MESSAGETYPE }

      debug log_format("message", "#{dhcp_in.to_s}")

      [dhcp_in, message_type]
    end

    def create_dhcp_packet(params)
      dhcp_out = params[:dhcp_class].new(:options => [DHCP::MessageTypeOption.new(:payload => [params[:message_type]])])

      # Verify instead that discover has the right mac address.
      dhcp_out.xid = params[:xid]
      dhcp_out.yiaddr = params[:yiaddr].to_i # port.ip
      dhcp_out.chaddr = params[:chaddr].to_a # port.mac
      dhcp_out.siaddr = params[:ipv4_address].to_i

      subnet_mask = IPAddr.new(IPAddr::IN4MASK, Socket::AF_INET).mask(params[:ipv4_prefix])

      dhcp_out.options << DHCP::ServerIdentifierOption.new(:payload => params[:ipv4_address].hton.unpack('C*'))
      dhcp_out.options << DHCP::IPAddressLeaseTimeOption.new(:payload => [ 0xff, 0xff, 0xff, 0xff ])
      dhcp_out.options << DHCP::BroadcastAddressOption.new(:payload => (params[:ipv4_network] | ~subnet_mask).hton.unpack('C*'))

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
