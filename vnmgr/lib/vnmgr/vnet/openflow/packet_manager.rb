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

    def insert(handler)
      cookie = self.datapath.switch.cookie_manager.acquire(:packet_handler)

      if cookie.nil? || @handlers.has_key?(cookie)
        p "Invalid cookie received: #{cookie.inspect}"
        return nil
      end
      
      @handlers[cookie] = handler

      handler.install(cookie)
    end

    def packet_in(port, message)
      handler = @handlers[message.cookie]

      handler.packet_in(port, message) if handler
    end

  end

end
    
