# -*- coding: utf-8 -*-

module Vnet::Openflow

  class PacketManager
    include Celluloid
    include Celluloid::Logger
    include Vnet::Constants::Openflow

    def initialize(dp)
      @datapath = dp
      @handlers = {}
      @tags = {}
    end

    def insert(handler, tag = nil, cookie = nil)
      cookie = @datapath.cookie_manager.acquire(:packet_handler) if cookie.nil?

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

    def link_cookies(main_cookie, sub_cookie)
      handler = @handlers[main_cookie]

      if main_cookie.nil? || handler.nil?
        error "packet_manager.link_cookies: invalid main cookie received (0x%x)" % main_cookie
        return nil
      end

      if sub_cookie.nil? || @handlers.has_key?(sub_cookie)
        error "packet_manager.link_cookies: invalid sub-cookie received (0x%x)" % sub_cookie
        return nil
      end
      
      @handlers[sub_cookie] = handler
      sub_cookie
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

      handler.cookie = nil if key == handler.cookie
    end

    def packet_in(port, message)
      handler = @handlers[message.cookie]

      if handler
        handler.packet_in(port, message)
      else
        debug "packet_manager: missing packet handler (0x%x)" % message.cookie
      end
    end

    def dispatch(key, &block)
      case key
      when Symbol
        handler = @tags[key]
      else
        handler = @handlers[key]
      end

      if handler.nil?
        error "packet_manager: block could not be dispatched for unknown cookie (0x%x)" % key
        return
      end

      block.call(key, handler)
    end

  end

end
    
