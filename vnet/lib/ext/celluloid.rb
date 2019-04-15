# -*- coding: utf-8 -*-

require 'celluloid/proxies/abstract_proxy'

module Celluloid
  class AbstractProxy
    def tap
      raise "OpenVNet has disabled tap method for all Celluloid proxies."
    end

    def nil?
      raise "OpenVNet has disabled nil? method for all Celluloid proxies."
    end
  end
end
