# -*- coding: utf-8 -*-

module Vnet::Services
  class Vnmgr
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :vnet_info

    def initialize
      info log_format("initalizing on node '#{DCell.me.id}'")

      @vnet_info = VnetInfo.new
    end

    def do_initialize
      info log_format('initializing managers')

      # Do linking here?...

      @vnet_info.start_managers

      info log_format('initialized managers')
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "vnmgr: #{message}" + (values ? " (#{values})" : '')
    end

  end
end
