# -*- coding: utf-8 -*-

module Vnet::Openflow::Interfaces

  # Remote interface types are any type of interface that is located
  # on other datapaths.

  class Remote < Base

    def initialize
      super

      @remote_mode = @mode
      @mode = :remote
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} interfaces/remote: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
