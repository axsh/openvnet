# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class PacketManager
    include Celluloid
    include Celluloid::Logger

    attr_reader :datapath

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
      handler.cookie = cookie
      handler.install
    end

    def remove(handler)
      if @handlers.delete(handler.cookie).nil?
        error "packet_manager: Could not find handler to remove."
        return
      end
      
      @datapath.del_cookie(handler.cookie)
    end

    def packet_in(port, message)
      handler = @handlers[message.cookie]
      handler.packet_in(port, message) if handler
    end

  end

end
    
