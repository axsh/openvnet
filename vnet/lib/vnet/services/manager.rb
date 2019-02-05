# -*- coding: utf-8 -*-

require 'vnet/manager_watchdog'

module Vnet::Services
  class Manager < Vnet::Manager
    include Vnet::Manager::Watchdog

    def initialize(info, options = {})
      @vnet_info = info

      @log_prefix = "#{self.class.name.to_s.demodulize.underscore}: "

      init_watchdog("#{self.class.name.to_s.demodulize.underscore}")

      # Call super last in order to ensure that the celluloid actor is
      # not activated before we have initialized the required
      # variables.
      super
    end

    def do_watchdog
      debug log_format('adding to service_watchdog')

      watchdog_register
    end

    def terminate
      debug log_format('removing from service_watchdog')

      watchdog_unregister
      super
    end

  end
end
