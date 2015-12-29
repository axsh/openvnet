# -*- coding: utf-8 -*-

# Sequal::Model plugin to inject mode validation and other features
# common for models that use modes.
#
# Each model must declear a 'C' alias for the module that contains
# constants to be used by BaseMode's methods. This includes the MODES
# list of valid modes.

module Vnet::Models
  module BaseMode

    # C = Vnet::Constants::Foo

    module InstanceMethods
    end

  end
end
