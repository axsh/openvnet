# -*- coding: utf-8 -*-

require 'net/dhcp'
require 'racket'

module Vnet::Openflow::Services

  class Dhcp < Base

    def initialize(params)
      super
      @dns_servers = {}
    end

    def install
      flows = []
      flows << flow_create(:controller,
                           table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 30,

                           match: {
                             :eth_type => 0x0800,
                             :ip_proto => 0x11,
                             :udp_dst => 67,
                             :udp_src => 68
                           },
                           match_interface: @interface_id,
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

      netid_to_routes = @dp_info.route_manager.select(network_id: network[:id], ingress: true)
      static_routes = find_static_routes(netid_to_routes.uniq { |r| r[:route_link_id] })

      client_info = find_client_infos(message.match.in_port, mac_info, ipv4_info).first
      return if client_info.nil?

      params = {
        :xid => dhcp_in.xid,
        :yiaddr => client_info[1][:ipv4_address],
        :chaddr => client_info[0][:mac_address],
        :ipv4_address => ipv4_info[:ipv4_address],
        :ipv4_network => network[:ipv4_network],
        :ipv4_prefix => network[:ipv4_prefix],
        :routes_info => static_routes
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
        params[:dns_server] = @dns_servers[ipv4_info[:network_id]]
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

    def add_network(network_id, cookie_id)
      if dns_server = @dp_info.service_manager.dns_server_for(network_id)
        add_dns_server(network_id, dns_server)
      end

      flows = []
      flows << flow_create(:default,
                           table: TABLE_FLOOD_SIMULATED,
                           goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 30,
                           match: {
                             :eth_type => 0x0800,
                             :ip_proto => 0x11,
                             :ipv4_dst => IPV4_BROADCAST,
                             :ipv4_src => IPV4_ZERO,
                             :udp_dst => 67,
                             :udp_src => 68
                           },
                           cookie: cookie_for_network(cookie_id),
                           match_network: network_id,
                           write_interface: @interface_id)
      @dp_info.add_flows(flows)
    end

    def remove_network(network_id)
      remove_dns_server(network_id)
    end

    def add_dns_server(network_id, dns_server)
      @dns_servers[network_id] = dns_server
    end

    def remove_dns_server(network_id)
      @dns_servers.delete(network_id)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} service/dhcp: #{message}" + (values ? " (#{values})" : '')
    end

    def find_static_routes(near_routes)
      # Overview: (near)vnetroute(s).route_link -> (far)vnetroute(s)
      static_routes = []
      near_routes.each do |rnear|
        router_ip_octets = nil
        far_routes = @dp_info.route_manager.select(route_link_id: rnear[:route_link_id],
                                                        egress: true,
                                                        not_network_id: rnear[:network_id])
        far_routes.each do |rfar|
          # get router/gateway target from near router's interface
          break unless router_ip_octets ||= get_router_octets(rnear)
          # get subnet to route from far router
          static_routes << [ ipaddr_to_octets(rfar[:ipv4_address]),
                             rfar[:ipv4_prefix],
                             router_ip_octets ]
        end
      end
      static_routes
    end

    def get_router_octets(arouter)
      near_interface = @dp_info.interface_manager.retrieve(id: arouter[:interface_id])
      ipv4_infos = near_interface.get_ipv4_infos(network_id: arouter[:network_id]).first
      ipaddr_to_octets(ipv4_infos[1][:ipv4_address])
    end
    
    def ipaddr_to_octets(ip)
      i = ip.to_i
      [ (i >> 24) % 256, (i >> 16) % 256, (i >> 8) % 256, i % 256 ]
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

      # http://tools.ietf.org/html/rfc3442  (option 121)
      if !params[:routes_info].empty?
        payload = params[:routes_info].collect_concat do |g|
          dst_ip, dst_pre, router_ip = g
          # keep only unmasked ints, following rfc3442
          keep = (dst_pre + 7 ) / 8
          [ dst_pre ] + dst_ip.first(keep) + router_ip
        end
        # TODO: subclass DHCP::Option and 121 constant, mainly so that
        # the to_s will give better debugging output
        dhcp_out.options << DHCP::Option.new(:type => 121, :payload => payload)
      end

      # if nw_services[:gateway]
      #   dhcp_out.options << DHCP::RouterOption.new(:payload => nw_services[:gateway].ip.to_short)
      # end

      dhcp_out.options << DHCP::SubnetMaskOption.new(:payload => subnet_mask.hton.unpack('C*'))

      # if nw_services[:dns]
      #   dhcp_out.options << DHCP::DomainNameOption.new(:payload => nw_services[:dns].domain_name.unpack('C*')) if nw_services[:dns].domain_name
      #   dhcp_out.options << DHCP::DomainNameServerOption.new(:payload => nw_services[:dns].ip.to_short) if nw_services[:dns].ip
      # end

      # TODO, check packet size does not exceed any known limits
      dhcp_out.options << DHCP::DomainNameServerOption.new.tap do |option|
        option.payload = (params[:dns_server] || "127.0.0.1").split(/[.,]/).map(&:to_i)
      end

      dhcp_out

    end

  end

end
