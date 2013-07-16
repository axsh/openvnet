# -*- coding: utf-8 -*-

module Vnet::Openflow

  module PortTunnel
    include FlowHelpers

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def tunnel?
      true
    end

    def install
      @datapath.switch.tunnel_manager.update_all_networks
    end
  end
end
