# -*- coding: utf-8 -*-

module Vnet::Services
  class Vnmgr
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :vnet_info

    finalizer :do_cleanup

    def initialize
      info log_format("initalizing on node '#{DCell.me.id}'")

      @vnet_info = VnetInfo.new
    end

    def service_init_timeout
      Vnet::Configurations::Vnmgr.conf.service_init_timeout
    end

    def start_services
      begin
        info log_format('initializing service managers')

        info log_format("waiting for service managers to finish initialization (timeout:#{service_init_timeout})")
        @vnet_info.initialize_service_managers(service_init_timeout)

        info log_format('initialized service managers')

      rescue Vnet::ManagerInitializationFailed => e
        # TODO: Replace with proper terminate.
        # @vnet_info.service_managers.each { |manager| manager.event_handler_drop_all }

        warn log_format("failed to initialize some managers due to timeout")
        raise e
      end
    end

    def do_cleanup
      info log_format("cleanup of service managers")

      @vnet_info.terminate_all_managers
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
