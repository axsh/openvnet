# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortTunnel
    include Vnmgr::Constants::Openflow

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
