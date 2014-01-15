# -*- coding: utf-8 -*-

require 'net/dns'
require 'racket'

module Vnet::Openflow::Services
  class Dns < Base
    def install
      @records ||= 1000.times.map { |i|
        ["proxy#{i}", "10.50.0.2"]
      }.each_with_object({}) do |(domain, ip), records|
        domain += "." unless domain =~ /\.$/
        records[domain] = IPAddr.new(ip)
      end

      #@reversed_records ||= @records.each_with_object(Hash.new{|h,k| h[k] = []}) do |(domain, ip), records|
      #  records[ip.reverse + "."] << domain
      #end

      update_dhcp_option

      flows = []
      flows << flow_create(:controller,
                           table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 30,

                           match: {
                             :eth_type => 0x0800,
                             :ip_proto => 0x11,
                             :udp_dst => 53,
                           },
                           match_interface: @interface_id,
                           cookie: self.cookie)

      @dp_info.add_flows(flows)
    end

    def packet_in(message)
      debug log_format('packet_in received')

      mac_info, ipv4_info, network = find_ipv4_and_network(message, message.ipv4_dst)
      return if network.nil?

      client_info = find_client_infos(message.match.in_port, mac_info, ipv4_info).first
      return if client_info.nil?

      raw_in_l2, raw_in_l3, raw_in_l4 = packet_udp_in(message)
      debug log_format('message: ', message.inspect)

      #debug log_format('records: ', @records.inspect)
      #debug log_format('reversed_records: ', @reversed_records.inspect)

      request = Net::DNS::Packet.parse(raw_in_l4.payload)
      #debug log_format('request: ', request.inspect)

      question = request.question.first
      #debug log_format('question: ', question.inspect)

      response = Net::DNS::Packet.new(question.qName)
      response.header.id = request.header.id
      response.header.qr = 1
      #response.header.ra = 1
      response.question = request.question

      case question.qType.to_s
      when "A" 
        if address = @records[question.qName]
          response.answer = Net::DNS::RR::A.new(
            :name    => question.qName,
            :ttl     => 300,
            :address => address
          )
          #response.header.anCount = 1
        end
      #when "PTR"
      #  @reversed_records[question.qName].each do |address|
      #    response.answer << Net::DNS::RR::PTR.new(
      #      :name    => question.qName,
      #      :ttl     => 300,
      #      :ptrdname => address
      #    )
      #    #response.header.anCount = 1
      #  end
      else
        # not implemented
        response.header.rCode = 4
      end

      debug log_format("DNS send", "output:#{response.inspect}")
      packet_udp_out(
        :out_port => message.in_port,
        :eth_src => mac_info[:mac_address],
        :src_ip => ipv4_info[:ipv4_address],
        :src_port => 53,
        :eth_dst => client_info[0][:mac_address],
        :dst_ip => client_info[1][:ipv4_address],
        :dst_port => message.udp_src,
        :payload => response.data
      )
    end

    def dns_server_for(network_id)
      case @dhcp_option
      when 0
        nil
      when 1, 2
        interface = @dp_info.interface_manager.item(id: @interface_id)
        private_dns = interface.get_ipv4_infos.map { |_, ipv4_info| ipv4_info.ipv4_address.to_s }.join(",")
        @dhcp_option == 1 ? public_dns + "," + private_dns : private_dns + "," + public_dns
      end

    end

    def add_network(network_id, cookie_id)
      @dp_info.service_manager.update_item(
        network_id: network_id,
        display_name: "dhcp",
        event: add_dns_server,
        network_id: network_id,
        dns_server: dns_server_for(network_id)
      )
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
                             :udp_dst => 53,
                           },
                           cookie: cookie_for_network(cookie_id),
                           match_network: network_id,
                           write_interface: @interface_id)
      @dp_info.add_flows(flows)
    end
  end
end
