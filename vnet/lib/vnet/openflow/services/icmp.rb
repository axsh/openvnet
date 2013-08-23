# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class Icmp < Base

    def initialize(params)
      super
      @entries = {}
    end

    def insert_interface(uuid, network, interface_map)
      return if @entries[uuid]

      debug "service::icmp.insert: uuid:#{uuid} interface_map:#{interface_map.inspect}"

      @entries[uuid] = {
        :network_number => interface_map.network_id,
        :mac_addr => Trema::Mac.new(interface_map.mac_addr),
        :ipv4_address => IPAddr.new(interface_map.ipv4_address, Socket::AF_INET),
      }

      catch_network_flow(network, {
                           :eth_type => 0x0800,
                           :eth_dst => Trema::Mac.new(interface_map.mac_addr),
                           :ip_proto => 0x01,
                           :ipv4_dst => IPAddr.new(interface_map.ipv4_address, Socket::AF_INET),
                         }, {
                           :network => network
                         })
    end

    def remove_interface(uuid)
      debug "service::icmp.remove: uuid:#{uuid}"
    end

    def packet_in(port, message)
      info "service::icmp.packet_in: port.port_info:#{port.port_info.inspect} message:#{message}"

      uuid, entry = @entries.find { |uuid,entry|
        port.network_number == entry[:network_number] && message.ipv4_dst == entry[:ipv4_address]
      }

      if entry.nil?
        info "service::icmp.packet_in: could not find handler"
        return
      end

      raw_in = icmpv4_in(message)

      case message.icmpv4_type
      when Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REQUEST
        icmpv4_out({ :out_port => message.in_port,

                     :eth_src => entry[:mac_addr],
                     :eth_dst => message.eth_src,
                     :ipv4_src => entry[:ipv4_address],
                     :ipv4_dst => message.ipv4_src,

                     :icmpv4_type => Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REPLY,
                     :icmpv4_id => raw_in.l4.id,
                     :icmpv4_sequence => raw_in.l4.sequence,

                     :payload => raw_in.l4.payload
                   })
      else
        debug "service::icmp.packet_in: unsupported op code '0x%x'" % message.icmpv4_code
      end
    end

  end

end
