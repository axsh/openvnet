# -*- coding: utf-8 -*-

require 'net/dhcp'
require 'racket'

module Vnet::Openflow::Services

  class Dhcp < Base
    attr_reader :vif_uuid
    attr_reader :service_mac
    attr_reader :service_ipv4

    def initialize(params)
      @datapath = params[:datapath]
      @network_id = params[:network_id]
      @network_type = params[:network_type]
      @vif_uuid = params[:vif_uuid]
      @service_mac = params[:service_mac]
      @service_ipv4 = params[:service_ipv4]

      @interface_id = params[:interface][:id]
    end

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
      flows << flow_create(:catch_flood_simulated,
                           match: {
                             :eth_type => 0x0800,
                             :ip_proto => 0x11,
                             :ipv4_dst => IPV4_BROADCAST,
                             :ipv4_src => IPV4_ZERO,
                             :udp_dst => 67,
                             :udp_src => 68
                           },
                           network_id: @network_id,
                           network_type: @network_type,
                           cookie: self.cookie)

      @datapath.add_flows(flows)
    end

    def packet_in(message)
      port_number = message.match.in_port
      port = @datapath.port_manager.port_by_port_number(port_number)

      debug "Dhcp.packet_in called."

      dhcp_in, message_type = parse_dhcp_packet(message)
      return if dhcp_in.nil? || message_type.empty? || message_type[0].payload.empty?

      # Verify dhcp_in values...

      network = find_network(message)
      return if network.nil?

      info "asdfasf: #{network.inspect}"

      params = {
        :xid => dhcp_in.xid,
        :yiaddr => port[:ipv4_address],
        :chaddr => port[:mac_address],
        :ipv4_network => network[:ipv4_network],
        :ipv4_prefix => network[:ipv4_prefix],
      }

      case message_type[0].payload[0]
      when $DHCP_MSG_DISCOVER
        debug "DHCP send: DHCP_MSG_OFFER."
        params[:dhcp_class] = DHCP::Offer
        params[:message_type] = $DHCP_MSG_OFFER
      when $DHCP_MSG_REQUEST
        debug "DHCP send: DHCP_MSG_ACK."
        params[:dhcp_class] = DHCP::ACK
        params[:message_type] = $DHCP_MSG_ACK
      else
        debug "DHCP send: no handler."
        return
      end

      dhcp_out = create_dhcp_packet(params)

      debug "DHCP send: output:#{dhcp_out.to_s}."

      udp_out({ :out_port => message.in_port,
                :eth_src => self.service_mac,
                :src_ip => self.service_ipv4,
                :src_port => 67,
                :eth_dst => port[:mac_address],
                :dst_ip => port[:ipv4_address],
                :dst_port => 68,
                :payload => dhcp_out.pack
              })
    end

    def parse_dhcp_packet(message)
      if !message.udp?
        debug "DHCP: Message is not UDP."
        return nil
      end

      raw_in_l2, raw_in_l3, raw_in_l4 = udp_in(message)

      dhcp_in = DHCP::Message.from_udp_payload(raw_in_l4.payload)
      message_type = dhcp_in.options.select { |each| each.type == $DHCP_MESSAGETYPE }

      debug "DHCP: message:#{dhcp_in.to_s}."

      [dhcp_in, message_type]
    end

    def find_network(message)
      ipv4_dst = message.ipv4_dst != IPV4_BROADCAST ? message.ipv4_dst : nil

      mac_info, ipv4_info = @datapath.interface_manager.get_ipv4_address(id: @interface_id,
                                                                         any_md: message.match.metadata,
                                                                         ipv4_address: ipv4_dst)
      return nil if ipv4_info.nil?

      @datapath.network_manager.network_by_id(ipv4_info[:network_id])
    end

    def create_dhcp_packet(params)
      dhcp_out = params[:dhcp_class].new(:options => [DHCP::MessageTypeOption.new(:payload => [params[:message_type]])])

      # Verify instead that discover has the right mac address.
      dhcp_out.xid = params[:xid]
      dhcp_out.yiaddr = params[:yiaddr].to_i # port.ip
      dhcp_out.chaddr = params[:chaddr].to_a # port.mac
      dhcp_out.siaddr = self.service_ipv4.to_i

      subnet_mask = IPAddr.new(IPAddr::IN4MASK, Socket::AF_INET).mask(params[:ipv4_prefix])

      dhcp_out.options << DHCP::ServerIdentifierOption.new(:payload => self.service_ipv4.hton.unpack('C*'))
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
