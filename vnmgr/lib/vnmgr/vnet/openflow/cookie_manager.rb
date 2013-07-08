# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class CookieCategory
    attr_reader :prefix
    attr_reader :bitshift
    attr_reader :next_cookie

    def initialize(prefix, bitshift)
      @prefix = prefix
      @bitshift = bitshift
      @next_cookie = prefix << bitshift
    end

    def range
      ((@prefix << bitshift)...((@prefix + 1) << bitshift))
    end

    def range_above
      return (0...0) if @next_cookie.nil?
      (@next_cookie...((@prefix + 1) << bitshift))
    end
    
    def range_below
      return (0...0) if @next_cookie.nil?
      ((@prefix << bitshift)...@next_cookie)
    end

    def update_next_cookie(cookie)
      return (@next_cookie = nil) if cookie.nil?
      return (@next_cookie = cookie) if @next_cookie.nil?

      @next_cookie = cookie + 1
      @next_cookie = (@prefix << bitshift) unless self.range.member?(@next_cookie)
    end
  end

  class CookieManager
    include Celluloid
    
    def initialize
      @categories = {}
      @cookies = {}
    end

    def create_category(name, prefix, bitshift)
      @categories[name] = CookieCategory.new(prefix, bitshift)
    end

    def acquire(name, value = nil)
      category = @categories[name]
      return nil if category.nil?

      cookie = find_cookie(category)

      # When the category has no more available cookies, the
      # next_cookie gets set to nil until one is released.
      category.update_next_cookie(cookie)

      return nil if cookie.nil?

      @cookies[cookie] = value
      cookie
    end

    def release(name, cookie)
      category = @categories[name]
      return nil if category.nil? || !@cookies.has_key?(cookie)

      category.update_next_cookie(cookie) if category.next_cookie.nil?      

      @cookies.delete(cookie)
    end

    private

    def find_cookie(category)
      category.range_above.each { |cookie| return cookie unless @cookies.has_key? cookie }
      category.range_below.each { |cookie| return cookie unless @cookies.has_key? cookie }
      nil
    end

  end

end
