# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortGre
    include Constants

    def flow_options
      @flow_options ||= {:cookie => self.port_number | (self.network_number << COOKIE_NETWORK_SHIFT)}
    end

    def gre?
      true
    end

    def install
      self.datapath.switch.network_manager.update_all_flows
    end
  end
end
