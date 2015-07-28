# -*- coding: utf-8 -*-

require 'net/dns'
require 'racket'

module Vnet::Core::Services
  class Dns < Base
    attr_reader :records
    attr_reader :dns_service

    def initialize(*args)
      super
      @records = Hash.new { |hash, key| hash[key] = [] }
      @public_dns_available_at = Time.now
      @dns_service = {}
    end

    def log_type
      'service/dns'
    end

    def install
      flows = []
      flows << flow_create(table: TABLE_OUT_PORT_INTERFACE_INGRESS,
                           priority: 30,

                           match: {
                             :eth_type => 0x0800,
                             :ip_proto => 0x11,
                             :udp_dst => 53,
                           },
                           match_interface: @interface_id,

                           actions: {
                             :output => Vnet::Openflow::Controller::OFPP_CONTROLLER
                           })

      @dp_info.add_flows(flows)
    end

    def packet_in(message)
      debug log_format('packet_in received')
      #debug log_format('message: ', message.inspect)

      mac_info, ipv4_info, network = find_ipv4_and_network(message, message.ipv4_dst)
      return if network.nil?

      client_info = find_client_infos(message.match.in_port, mac_info, ipv4_info).first
      return if client_info.nil?

      raw_in_l2, raw_in_l3, raw_in_l4 = packet_udp_in(message)

      request = Net::DNS::Packet.parse(raw_in_l4.payload)
      #debug log_format('request: ', request.inspect)

      question = request.question.first
      #debug log_format('question: ', question.inspect)

      response = process_dns_request(request)

      #debug log_format("DNS send", "output:#{response.inspect}")
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

    def add_network(network_id, cookie_id)
      add_dns_server(network_id)

      flows = []
      flows << flow_create(table: TABLE_FLOOD_SIMULATED,
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

    def remove_network(network_id)
      remove_dns_server(network_id)
    end

    def add_dns_record(dns_record_map)
      name = normalize_record_name(dns_record_map.name)
      @records[name] << {
        ipv4_address: IPAddr.new(dns_record_map.ipv4_address, Socket::AF_INET),
        ttl: dns_record_map.ttl
      }
    end

    def remove_dns_record(dns_record_map)
      name = normalize_record_name(dns_record_map.name)
      @records[name].delete_if do |record|
        record[:ipv4_address].to_i == dns_record_map.ipv4_address
      end
    end

    def set_dns_service(dns_service_map)
      @dns_service.merge!(
        public_dns: dns_service_map.public_dns
      )
      @networks.each do |_, network|
        add_dns_server(network[:network_id])
      end
    end

    def update_dns_service(dns_service_map)
      [:public_dns].each do |key|
        @dns_service[key] = dns_service_map[key]
      end
    end

    def clear_dns_service
      @dns_service.clear
      @records.clear
      @networks.each do |_, network|
        remove_dns_server(network[:network_id])
      end
    end

    def dns_server_for(network_id)
      interface = @dp_info.interface_manager.wait_for_loaded(id: @interface_id, 10, true)

      ipv4_info = interface.get_ipv4_infos(network_id: network_id).map(&:last).detect do |ipv4_info|
        ipv4_info[:network_id] == network_id
      end
      ipv4_info ? ipv4_info[:ipv4_address].to_s : nil
    end

    def add_dns_server(network_id)
      if dns_server = dns_server_for(network_id)
        Celluloid::Actor.current.add_dns_server(network_id, dns_server)
      end
    end

    def remove_dns_server(network_id)
      Celluloid::Actor.current.remove_dns_server(network_id)
    end

    def process_dns_request(request)
      response = internal_lookup(request)
      if response.answer.empty?
        if @dns_service[:public_dns]
          response = external_lookup(request)
        else
          response = server_not_available_response(request)
        end
      end
      response
    end

    def internal_lookup(request)
      create_dns_response(request) do |response, question|
        case question.qType.to_s
        when "A"
          records = @records[question.qName]
          unless records.empty?
            # Multiple addresses are not suppoerted atm.
            record = records.first

            ipv4_address = record[:ipv4_address]
            ttl = record[:ttl] || 300 # TODO should be configurable
            response.answer = Net::DNS::RR::A.new(
              :name    => question.qName,
              :ttl     => ttl,
              :address => ipv4_address
            )
            #response.header.anCount = 1
          end
        #when "PTR"
        #  @reversed_records[question.qName].each do |address|
        #    response.answer << Net::DNS::RR::PTR.new(
        #      :name    => question.qName,
        #      :ttl     => ttl,
        #      :ptrdname => address
        #    )
        #    #response.header.anCount = 1
        #  end
        else
          response.header.rCode = Net::DNS::Header::RCode::NOTIMPLEMENTED
        end
      end
    end

    def external_lookup(request)
      if @public_dns_available_at > Time.now
        return server_not_available_response(request)
      end

      question = request.question.first
      public_dns = (@dns_service[:public_dns] || "").split(",")
      resolver = Net::DNS::Resolver.new(nameservers: public_dns)
      begin
        resolver.search(question.qName, question.qType.to_i, question.qClass.to_i).tap do |response|
          response.header.id = request.header.id
        end
      rescue TimeoutError => e
        warn log_format("public dns timeout", public_dns)
        @public_dns_available_at = Time.now + 60 # TODO should be configurable
        server_not_available_response(request)
      end
    end

    def server_not_available_response(request)
      create_dns_response(request) do |response, _|
        response.header.rCode = Net::DNS::Header::RCode::SERVER
      end
    end

    def create_dns_response(request, &block)
      question = request.question.first
      Net::DNS::Packet.new(question.qName).tap do |response|
        response.header.id = request.header.id
        response.header.qr = 1
        #response.header.ra = 1
        response.question = request.question
        yield response, question if block_given?
      end
    end

    def normalize_record_name(name)
      name.chomp(".") + "."
    end
  end
end
