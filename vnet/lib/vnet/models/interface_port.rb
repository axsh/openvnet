# -*- coding: utf-8 -*-

module Vnet::Models
  class InterfacePort < Base
    plugin :paranoia_is_deleted

    many_to_one :interface
    many_to_one :datapath

    def validate
      super

      if singular != true && !singular.nil?
        errors.add(:singular, 'must be set to either true or null')
      end
    end

  end
end
