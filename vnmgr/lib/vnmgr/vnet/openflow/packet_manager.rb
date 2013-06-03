# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class PacketManager
    include Celluloid

    attr_reader :datapath
    attr_reader :handlers

    def initialize(dp)
      @datapath = dp
      @handlers = {}
    end

    def insert(cookie, handler)
      # Sanity-check cookie.
      return nil if @handlers.has_key? cookie
      
      @handlers[cookie] = handler
    end

    def packet_in(port, message)
      handler = @handlers[message.cookie]

      handler.packet_in(message) if handler
    end

  end

end
    
