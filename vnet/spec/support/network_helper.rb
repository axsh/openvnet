# -*- coding: utf-8 -*-

require 'ipaddr'

class MacAddr
  def initialize(addr)
    case addr
    when Integer
      @addr_s = ("%012x" % addr).gsub(/(\w{2})/, '\1:').chop
      @addr_i = addr
    when String
      @addr_s = addr
      @addr_i = addr.delete(":").hex
    end
  end

  def to_i
    @addr_i
  end

  def to_s
    @addr_s
  end
end

def random_mac_s
  6.times.map{ "%02x" % rand(0xFF) }.join(":")
end

def random_mac_i
  rand(2**48)
end

def random_mac
  MacAddr.new(rand(2**48))
end

def random_ipv4_s(mask=24)
  IPAddr.new(rand(2**32),Socket::AF_INET).mask(mask).to_s
end

def random_ipv4_i(mask=24)
  IPAddr.new(rand(2**32),Socket::AF_INET).mask(mask).to_i
end

def random_ipv4(mask=24)
  IPAddr.new(rand(2**32),Socket::AF_INET).mask(mask)
end
