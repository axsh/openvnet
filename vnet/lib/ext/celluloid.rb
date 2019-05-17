# -*- coding: utf-8 -*-

require 'celluloid/proxies/abstract_proxy'

module Celluloid
  class AbstractProxy
    # Disable some commonly used methods that do not execute locally
    # as would be expected. When called on an actor proxy object these
    # get sent to the actor context, e.g. tap may send the code block
    # to a remote dcell node to be executed.

    def tap
      raise "OpenVNet has disabled tap method for all Celluloid proxies."
    end

    def nil?
      raise "OpenVNet has disabled nil? method for all Celluloid proxies."
    end
  end
end
