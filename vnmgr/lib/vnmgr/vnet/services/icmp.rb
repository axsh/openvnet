# -*- coding: utf-8 -*-

require 'racket'

module Vnmgr::VNet::Services

  class Icmp < Vnmgr::VNet::Openflow::PacketHandler

    def initialize(params)
      @datapath = params[:datapath]
      @entries = {}
    end

    def install
    end

    def insert_vif(uuid, network, vif_map)
      debug "service::icmp.insert: uuid:#{uuid} vif_map:#{vif_map.inspect}"
    end

    def remove_vif(uuid)
      debug "service::icmp.remove: uuid:#{uuid}"
    end

    def packet_in(port, message)
      debug "service::icmp.packet_in called."
    end

  end

end
