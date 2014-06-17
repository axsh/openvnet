# -*- coding: utf-8 -*-

module Vnet::Models

  class InterfacePort < Base
    many_to_one :interface
    many_to_one :datapath

    def validate
      super
      errors.add(:singular, 'must be set to either true or null') if singular != true && !singular.nil?
    end

  end

end
