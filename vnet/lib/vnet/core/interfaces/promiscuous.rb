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
      # flows << flow_create(table: TABLE_INTERFACE_INGRESS_CLASSIFIER,
      #                      goto_table: TABLE_INTERFACE_INGRESS_PROMISCUOUS,
      #                      priority: 10,
      #                      match_interface: @id)
    end

  end

end
