# -*- coding: utf-8 -*-

module Vnet::Models

  class ActivePort < Base
    plugin :paranoia_is_deleted

    use_modes Vnet::Constants::ActivePort::MODES

    many_to_one :datapath

    def validate
      super

      if !(port_number > 0 && port_number < (1 << 32))
        errors.add(:port_number, 'invalid port_number value')
      end
    end

  end

end
