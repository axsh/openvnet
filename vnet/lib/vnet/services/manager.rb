# -*- coding: utf-8 -*-

module Vnet::Services
  class Manager < Vnet::Manager

    def initialize(info, options = {})
      @vnet_info = info

      @log_prefix = "#{self.class.name.to_s.demodulize.underscore}: "

      # Call super last in order to ensure that the celluloid actor is
      # not activated before we have initialized the required
      # variables.
      super
    end

  end
end
