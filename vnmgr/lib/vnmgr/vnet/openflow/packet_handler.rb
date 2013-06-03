# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class PacketHandler

    attr_reader :datapath

    def initialize(dp)
      @datapath = dp
    end

    def packet_in(message)
      p "PacketHandler.packet_in called."
    end

    def packet_out(data)
      p "PacketHandler.packet_out called."
    end

    def arp_out(data)
    end

  end

end
