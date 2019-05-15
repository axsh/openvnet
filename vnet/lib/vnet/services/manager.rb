# -*- coding: utf-8 -*-

module Vnet::Services
  class Manager < Vnet::Manager
    include Vnet::Watchdog

    def initialize(info, options = {})
      @vnet_info = info

      @log_prefix = "#{self.class.name.to_s.demodulize.underscore}: "

      init_watchdog("#{self.class.name.to_s.demodulize.underscore}")

      # Call super last in order to ensure that the celluloid actor is
      # not activated before we have initialized the required
      # variables.
      super
    end

    def do_register_watchdog
      watchdog_register
    end

    def do_unregister_watchdog
      watchdog_unregister
    end

  end
end
