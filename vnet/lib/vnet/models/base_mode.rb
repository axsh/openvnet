# -*- coding: utf-8 -*-

# Sequal::Model plugin to inject mode validation and other features
# common for models that use modes.
#
# Each model must declear a 'C' alias for the module that contains
# constants to be used by BaseMode's methods. This includes the MODES
# list of valid modes.

module Vnet::Models
  module BaseMode

    module InstanceMethods
      def valid_modes
        self.class.valid_modes
      end

      def validate
        validates_includes(self.class.valid_modes, :mode)
        super
      end
    end

    module ClassMethods
      def valid_modes
        @valid_modes
      end

      def set_valid_modes(modes)
        @valid_modes = modes
      end
    end

  end
end
