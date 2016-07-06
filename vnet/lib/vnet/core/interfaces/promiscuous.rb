# -*- coding: utf-8 -*-

module Vnet::Core::Interfaces

  class Promiscuous < IfBase

    def log_type
      'interface/promiscuous'
    end

    def install
      flows = []

      flows_for_base(flows)

      @dp_info.add_flows(flows)
    end

    #
    # Internal methods:
    #

    private

    def flows_for_base(flows)
    end

  end

end
