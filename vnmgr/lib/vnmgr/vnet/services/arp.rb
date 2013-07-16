# -*- coding: utf-8 -*-

require 'racket'

module Vnmgr::VNet::Services

  class Arp < Base

    def initialize(params)
      super
      @entries = {}
    end

    def insert_vif(uuid, network, vif_map)
      return if @entries[uuid]

      debug "service::arp.insert: uuid:#{uuid} vif_map:#{vif_map.inspect}"

      @entries[uuid] = {
        :network_number => vif_map.network_id,
        :mac_addr => Trema::Mac.new(vif_map.mac_addr),
        :ipv4_address => IPAddr.new(vif_map.ipv4_address, Socket::AF_INET),
      }

      catch_network_flow(network, {
                           :eth_dst => MAC_BROADCAST,
                           :eth_type => 0x0806,
                           :arp_tha => MAC_ZERO,
                           :arp_tpa => IPAddr.new(vif_map.ipv4_address, Socket::AF_INET),
                         }, {
                           :network => network
                         })
      catch_network_flow(network, {
                           :eth_dst => Trema::Mac.new(vif_map.mac_addr),
                           :eth_type => 0x0806,
                           :arp_tha => Trema::Mac.new(vif_map.mac_addr),
                           :arp_tpa => IPAddr.new(vif_map.ipv4_address, Socket::AF_INET),
                         }, {
                           :network => network
                         })
    end

    def remove_vif(uuid)
      debug "service::arp.remove: uuid:#{uuid}"
    end

    def packet_in(port, message)
      info "service::arp.packet_in: port.port_info:#{port.port_info.inspect} message:#{message}"

      uuid, entry = @entries.find { |uuid,entry|
        port.network_number == entry[:network_number] && message.arp_tpa == entry[:ipv4_address]
      }

      if entry.nil?
        info "service::arp.packet_in: could not find handler"
        return
      end

      arp_out({ :out_port => message.in_port,
                :eth_src => entry[:mac_addr],
                :eth_dst => message.eth_src,
                :op_code => Racket::L3::ARP::ARPOP_REPLY,
                :sha => entry[:mac_addr],
                :spa => entry[:ipv4_address],
                :tha => message.eth_src,
                :tpa => message.arp_spa,
              })
    end

  end

end
