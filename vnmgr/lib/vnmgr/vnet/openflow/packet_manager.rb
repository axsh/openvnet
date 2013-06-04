# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class PacketManager
    include Celluloid
    include Celluloid::Logger

    attr_reader :datapath
    attr_reader :handlers

    def initialize(dp)
      @datapath = dp
      @handlers = {}
    end

    def insert(handler)
      cookie = @datapath.switch.cookie_manager.acquire(:packet_handler)

      if cookie.nil? || @handlers.has_key?(cookie)
        error "packet_manager: Invalid cookie received: #{cookie.inspect}"
        return nil
      end
      
      @handlers[cookie] = handler

      handler.install(cookie)
    end

    def remove(handler)
      key = @handlers.key(handler)

      if key.nil?
        error "packet_manager: Could not find handler to remove."
        return
      end

      @handlers.delete(key)
      @datapath.del_cookie(key)
    end

    def packet_in(port, message)
      handler = @handlers[message.cookie]

      handler.packet_in(port, message) if handler
    end

  end

end
    
