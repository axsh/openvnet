# -*- coding: utf-8 -*-

module Vnet::Core::ActivePorts

  class Tunnel < Base

    def mode
      :tunnel
    end

    def log_type
      'active_port/tunnel'
    end

    class << self
      include Vnet::Openflow::FlowHelpers

      # TODO: Make this flow default for the switch.
      def add_flows_for_id(dp_info, item_id)
        # flows = []

        # dp_info.add_flows(flows)
      end

    end
  end

end
