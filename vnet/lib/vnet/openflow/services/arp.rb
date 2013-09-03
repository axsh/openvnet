# -*- coding: utf-8 -*-

require 'racket'

module Vnet::Openflow::Services

  class Arp < Base

    def initialize(params)
      super
      @entries = {}
    end

    def insert_interface(uuid, network, interface_map)
      return if @entries[uuid]

      debug "service::arp.insert: network:#{network.uuid}/#{network.network_id} interface_uuid:#{uuid}"

      @entries[uuid] = {
        :network_number => interface_map.network_id,
        :mac_addr => Trema::Mac.new(interface_map.mac_addr),
        :ipv4_address => IPAddr.new(interface_map.ipv4_address, Socket::AF_INET),
      }

      catch_network_flow(network, {
                           :eth_dst => MAC_BROADCAST,
                           :eth_type => 0x0806,
                           :arp_op => 1,
                           :arp_tha => MAC_ZERO,
                           :arp_tpa => IPAddr.new(interface_map.ipv4_address, Socket::AF_INET),
                         }, {
                           :network => network
                         })
      catch_network_flow(network, {
                           :eth_dst => Trema::Mac.new(interface_map.mac_addr),
                           :eth_type => 0x0806,
                           :arp_op => 1,
                           :arp_tpa => IPAddr.new(interface_map.ipv4_address, Socket::AF_INET),
                         }, {
                           :network => network
                         })
    end

    def remove_interface(uuid)
      debug "service::arp.remove: uuid:#{uuid}"
    end

    def packet_in(message)
      port_number = message.match.in_port
      port = @datapath.port_manager.port_by_port_number(port_number)

      arp_tpa = message.arp_tpa
      arp_spa = message.arp_spa

      debug "service::arp.packet_in: port_number:#{port_number} name:#{port[:name]} arp_spa:#{arp_spa} arp_tpa:#{arp_tpa}"

      uuid, entry = @entries.find { |uuid,entry|
        port[:network_id] == entry[:network_id] && arp_tpa == entry[:ipv4_address]
      }

      if entry.nil?
        info "service::arp.packet_in: could not find handler"
        return
      end

      arp_out({ :out_port => message.in_port,
                :in_port => OFPP_CONTROLLER,
                :eth_src => entry[:mac_addr],
                :eth_dst => message.eth_src,
                :op_code => Racket::L3::ARP::ARPOP_REPLY,
                :sha => entry[:mac_addr],
                :spa => entry[:ipv4_address],
                :tha => message.eth_src,
                :tpa => arp_spa,
              })
    end

  end

end
