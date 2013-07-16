# -*- coding: utf-8 -*-

module Vnet::Openflow

  class PacketManager
    include Celluloid
    include Celluloid::Logger

    def initialize(dp)
      @datapath = dp
      @handlers = {}
      @tags = {}
    end

    def insert(handler, tag = nil)
      cookie = @datapath.switch.cookie_manager.acquire(:packet_handler)

      if cookie.nil? || @handlers.has_key?(cookie)
        error "packet_manager: invalid cookie received '#{cookie.inspect}'"
        return nil
      end
      
      if tag
        @tags[tag] = handler
        handler.tag = tag
      end

      @handlers[cookie] = handler
      handler.cookie = cookie
      handler.install

      cookie
    end

    def remove(key)
      case key
      when Symbol
        handler = @tags[key]
      else
        handler = @handlers[key]
      end

      if @handlers.delete(handler.cookie).nil?
        error "packet_manager: could not find handler to remove"
        return
      end
      
      @datapath.del_cookie(handler.cookie)
      @tags.delete(handler.tags) if handler.tag
    end

    def packet_in(port, message)
      handler = @handlers[message.cookie]
      handler.packet_in(port, message) if handler
    end

    def dispatch(key, &block)
      case key
      when Symbol
        handler = @tags[key]
      else
        handler = @handlers[key]
      end

      if handler.nil?
        error "packet_manager: block could not be dispatched for unknown cookie '%0x'" % key
        return
      end

      block.call(handler)
    end

  end

end
    
