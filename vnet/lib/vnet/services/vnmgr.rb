# -*- coding: utf-8 -*-

module Vnet::Services
  class Vnmgr
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :vnet_info

    def initialize
      @vnet_info = VnetInfo.new
    end

    def do_initialize
      info log_format('initializing managers')

      # Do linking here?...

      @vnet_info.managers { |manager|
        managers.each { |manager| manager.event_handler_queue_only }
        managers.each { |manager| manager.async.start_initialize }
        managers.each { |manager| manager.wait_for_initialized(nil) }
        managers.each { |manager| manager.event_handler_active }
      }

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
